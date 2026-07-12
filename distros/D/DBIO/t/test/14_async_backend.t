use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Future::Immediate;
use DBIO::Test::Storage;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;

# ADR 0030: async is an explicit, per-connection mode resolved through a mode
# registry. A mode name maps to an embedded backend class; the backend is built
# per-instance via ->new($schema) + connect_info. The mock storage defaults to
# the 'immediate' mode. This test drives the whole selection model on mock
# storage only -- no event loop, no real database.

# --- Two in-file mock backends, registered under distinct mode names ----------
# Each tags its results so the resolved CHOICE is observable. They override new()
# to dodge base DBIO::Storage construction (no loop, no pool), record the six
# *_async op names, and resolve to an immediate DBIO::Future::Immediate.

{
  package My::Mock::AsyncA;
  use base 'DBIO::Storage::Async';
  sub new { my ($c, $s) = @_; bless { schema => $s, calls => [], disconnected => 0 }, $c }
  sub future_class { 'DBIO::Future::Immediate' }
  sub connect_info { my $s = shift; $s->{connect_info} = shift if @_; $s->{connect_info} }
  sub disconnect { $_[0]{disconnected}++ }
  sub select_async        { push @{$_[0]{calls}}, 'select';        DBIO::Future::Immediate->done('A:select') }
  sub select_single_async { push @{$_[0]{calls}}, 'select_single'; DBIO::Future::Immediate->done('A:select_single') }
  sub insert_async        { push @{$_[0]{calls}}, 'insert';        DBIO::Future::Immediate->done('A:insert') }
  sub update_async        { push @{$_[0]{calls}}, 'update';        DBIO::Future::Immediate->done('A:update') }
  sub delete_async        { push @{$_[0]{calls}}, 'delete';        DBIO::Future::Immediate->done('A:delete') }
  sub txn_do_async        { push @{$_[0]{calls}}, 'txn_do';        DBIO::Future::Immediate->done('A:txn_do') }

  package My::Mock::AsyncB;
  use base 'DBIO::Storage::Async';
  sub new { my ($c, $s) = @_; bless { schema => $s, calls => [] }, $c }
  sub future_class { 'DBIO::Future::Immediate' }
  sub connect_info { my $s = shift; $s->{connect_info} = shift if @_; $s->{connect_info} }
  sub disconnect { 1 }
  sub select_async { push @{$_[0]{calls}}, 'select'; DBIO::Future::Immediate->done('B:select') }
}

DBIO::Storage::DBI->register_async_mode( mock_a => 'My::Mock::AsyncA' );
DBIO::Storage::DBI->register_async_mode( mock_b => 'My::Mock::AsyncB' );

# Set the chosen mode on a mock storage exactly as connect would, clearing the
# resolved-backend cache (the connect_info path clears it; a direct setter must
# too). Returns the storage for chaining.
sub set_mode {
  my ($storage, $mode) = @_;
  $storage->_async_mode($mode);
  delete $storage->{_async_storage_obj};
  return $storage;
}

# -----------------------------------------------------------------------
# Registry resolution: register + MRO-walk lookup, plus the core 'immediate'
# -----------------------------------------------------------------------
{
  is( DBIO::Storage::DBI->_resolve_async_mode_class('mock_a'), 'My::Mock::AsyncA',
    'registry resolves a registered generic mode to its backend class' );
  is( DBIO::Storage::DBI->_resolve_async_mode_class('immediate'), 'DBIO::Future::Immediate',
    "core registers 'immediate' -> DBIO::Future::Immediate" );
  is( DBIO::Storage::DBI->_resolve_async_mode_class('nope'), undef,
    'unregistered mode resolves to undef' );

  # The driver storage class (DBIO::Test::Storage) inherits the generic
  # registrations via the MRO walk.
  is( DBIO::Test::Storage->_resolve_async_mode_class('mock_a'), 'My::Mock::AsyncA',
    'driver subclass inherits generic mode registrations through the MRO' );
}

# -----------------------------------------------------------------------
# A registered mock mode is built per-instance and answers all six *_async
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'mock_a');

  my $async = $storage->_async_storage;
  isa_ok $async, 'My::Mock::AsyncA',
    'mode mock_a builds the registered backend for this instance';
  is $storage->async, $async,
    'public async() returns the same built backend';
  is $async->{schema}, $schema,
    'backend was built with ->new($schema)';
  is $storage->future_class, 'DBIO::Future::Immediate',
    'future_class delegates to the live backend';

  for my $op (qw(select select_single insert update delete txn_do)) {
    my $method = "${op}_async";
    my $f = $storage->$method();
    isa_ok $f, 'DBIO::Future::Immediate', "$method returns a Future";
    is scalar $f->get, "A:$op", "$method routes to the backend (A:$op)";
  }
  is_deeply $async->{calls},
    [qw(select select_single insert update delete txn_do)],
    'all six ops recorded on the backend in order';
}

# -----------------------------------------------------------------------
# Three modes in parallel: same schema class, three live instances at once
# (immediate + mock_a + mock_b), each answering *_async independently
# -----------------------------------------------------------------------
{
  my $imm = DBIO::Test->init_schema;            # mock default: 'immediate'
  my $a   = DBIO::Test->init_schema;
  my $b   = DBIO::Test->init_schema;

  set_mode($a->storage, 'mock_a');
  set_mode($b->storage, 'mock_b');

  is $imm->storage->_async_mode, 'immediate', 'instance 1 is immediate';
  is $a->storage->_async_mode,   'mock_a',    'instance 2 is mock_a';
  is $b->storage->_async_mode,   'mock_b',    'instance 3 is mock_b';

  # immediate: no embedded backend, in-process degrade
  ok !defined $imm->storage->_async_storage,
    'immediate instance has no embedded backend';
  isa_ok $a->storage->_async_storage, 'My::Mock::AsyncA', 'mock_a instance backend';
  isa_ok $b->storage->_async_storage, 'My::Mock::AsyncB', 'mock_b instance backend';

  # All three answer select_async simultaneously, each its own way.
  my $fi = $imm->storage->txn_do_async(sub { 'I:txn' });
  is scalar $fi->get, 'I:txn',  'immediate instance degrades txn_do_async in-process';
  is scalar $a->storage->select_async()->get, 'A:select',
    'mock_a instance routes select_async to backend A';
  is scalar $b->storage->select_async()->get, 'B:select',
    'mock_b instance routes select_async to backend B';

  # They are genuinely distinct live backends.
  isnt $a->storage->_async_storage, $b->storage->_async_storage,
    'the two backend instances are distinct objects';
}

# -----------------------------------------------------------------------
# Unavailable mode croaks loudly (explicit-or-it-croaks)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'totally_not_registered');

  throws_ok { $storage->_async_storage }
    qr/async mode 'totally_not_registered' is not available/,
    'an unregistered mode croaks when resolved';
  throws_ok { $storage->select_async }
    qr/async mode 'totally_not_registered' is not available/,
    'select_async on an unavailable-mode instance croaks too';
}

# A mode registered to an uninstalled class croaks naming the class to install.
{
  DBIO::Storage::DBI->register_async_mode( ghost => 'No::Such::Async::Backend' );

  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'ghost');

  throws_ok { $storage->_async_storage }
    qr/async mode 'ghost' is not available -- install No::Such::Async::Backend/,
    'a registered-but-uninstalled mode croaks naming the missing dist';
}

# -----------------------------------------------------------------------
# *_async on a sync instance croaks (no silent degrade)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, undef);   # undef mode == sync

  ok !defined $storage->_async_mode, 'sync instance has no async mode';
  ok !defined $storage->_async_storage, 'sync instance has no embedded backend';

  throws_ok { $storage->select_async }
    qr/not an async connection/,
    'select_async on a sync instance croaks';
  throws_ok { $storage->txn_do_async(sub { 1 }) }
    qr/not an async connection/,
    'txn_do_async on a sync instance croaks';
}

# -----------------------------------------------------------------------
# 'immediate' mode: degrade in-process to an immediately-resolved Future
# (the former silent default, now a deliberately-named mode)
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = $schema->storage;

  is $storage->_async_mode, 'immediate',
    'mock storage defaults to the immediate mode';
  ok !defined $storage->_async_storage,
    'immediate mode has no embedded backend';
  is $storage->future_class, 'DBIO::Future::Immediate',
    'immediate future_class is DBIO::Future::Immediate';

  my $f = $storage->txn_do_async(sub { 42 });
  isa_ok $f, 'DBIO::Future::Immediate', 'immediate txn_do_async returns a Future';
  ok $f->is_ready,         'immediate future is ready';
  is scalar $f->get, 42,   'immediate future resolves with the coderef result';

  # immediate failure propagates through the future
  my $ff = $storage->txn_do_async(sub { die "boom\n" });
  ok $ff->is_failed, 'immediate txn_do_async failure becomes a failed future';
}

# -----------------------------------------------------------------------
# connect_info reads { async => MODE } and fixes the instance mode
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = $schema->storage;

  $storage->connect_info([ sub { }, { async => 'mock_a' } ]);
  is $storage->_async_mode, 'mock_a',
    'connect_info extracts { async => MODE } into the instance mode';

  isa_ok $storage->_async_storage, 'My::Mock::AsyncA',
    'the connect-chosen mode builds the right backend';

  # A subsequent connect_info without async resets the instance to sync.
  $storage->connect_info([ sub { } ]);
  ok !defined $storage->_async_mode,
    'connect_info without async resets the instance to sync';
}

# -----------------------------------------------------------------------
# disconnect tears down the embedded async backend
# -----------------------------------------------------------------------
{
  my $schema  = DBIO::Test->init_schema;
  my $storage = set_mode($schema->storage, 'mock_a');

  my $async = $storage->_async_storage;     # build + cache the backend
  isa_ok $async, 'My::Mock::AsyncA', 'backend live before disconnect';

  $storage->disconnect;

  is $async->{disconnected}, 1, 'async backend disconnect() was called once';
  ok !$storage->_fake_connected, 'sync mock storage is disconnected too';
}

done_testing;
