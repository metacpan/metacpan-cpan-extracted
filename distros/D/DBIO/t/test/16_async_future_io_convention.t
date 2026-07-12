use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util ();

use DBIO::Test;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Test::Storage;

# ADR 0030 refinement (karr #65): the future_io async mode resolves its
# per-driver transport adapter by CONVENTION -- ref($storage) . '::Async' --
# derived off the concrete, driver-determined storage class (parallel to the
# sync driver storage DBIO::X::Storage). This drives that resolution entirely
# through the mock storage: no event loop, no real database, no Future::IO dep.
#
# The adapter is a fully-synchronous DBIO::Storage::Async that fills the
# transport seams -- the same sync-future/pool pattern used by
# t/test/15_async_orchestration.t -- so a CRUD op can round-trip in-process.

# --- A synchronous, contract-compliant Future ------------------------------
# The orchestration relies on real DBIO::Future chaining: ->then flattens a
# returned Future and (2-arg) routes a failure to on_fail. This shim provides
# that synchronously (mirrors t/test/15).
{
  package AsyncConv::SyncFuture;

  sub done { my $c = shift; bless { failed => 0, result => [@_] }, ref($c) || $c }
  sub fail { my ($c, $e) = @_; bless { failed => 1, error => $e, result => [] }, ref($c) || $c }

  sub is_ready  { 1 }
  sub is_failed { $_[0]->{failed} ? 1 : 0 }

  sub get {
    my $self = shift;
    die $self->{error} if $self->{failed};
    return wantarray ? @{ $self->{result} } : $self->{result}[0];
  }

  sub then {
    my ($self, $on_done, $on_fail) = @_;
    if ($self->{failed}) {
      return $self unless $on_fail;
      return _dispatch($on_fail, $self->{error});
    }
    return _dispatch($on_done, @{ $self->{result} });
  }

  sub catch {
    my ($self, $on_fail) = @_;
    return $self unless $self->{failed};
    return _dispatch($on_fail, $self->{error});
  }

  sub _dispatch {
    my ($cb, @args) = @_;
    my @r = eval { $cb->(@args) };
    return __PACKAGE__->fail($@) if $@;
    return $r[0]
      if @r == 1 && Scalar::Util::blessed($r[0]) && $r[0]->isa(__PACKAGE__);
    return __PACKAGE__->done(@r);
  }
}

# --- A fake pool -----------------------------------------------------------
{
  package AsyncConv::SyncPool;

  sub new { bless { released => [], available => 1 }, shift }
  sub acquire     { AsyncConv::SyncFuture->done('CONN') }
  sub acquire_txn { AsyncConv::SyncFuture->done('CONN') }
  sub release     { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub available   { $_[0]->{available} }
  sub shutdown    { $_[0]->{available} = 0 }
}

# --- The transport adapter for the WITH-adapter driver ---------------------
# A concrete DBIO::Storage::Async that overrides only the transport seams, all
# resolving immediately. This is named exactly as the convention sibling of
# AsyncConv::WithAdapter::Storage below, so the core resolver discovers it.
{
  package AsyncConv::WithAdapter::Storage::Async;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured}  = [];
    $self->{next_rows} = [];
    return $self;
  }

  sub future_class    { 'AsyncConv::SyncFuture' }
  sub sql_maker_class { 'DBIO::SQLMaker' }
  sub _sql_maker_args { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }
  sub pool { $_[0]->{pool} ||= AsyncConv::SyncPool->new }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 0 };
    return $self->future_class->done(@{ $self->{next_rows} });
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, pinned => 1, conn => $conn };
    return $self->future_class->done(@{ $self->{next_rows} });
  }

  sub _last_sql { $_[0]->{captured}[-1]{sql} }
}

# Two more valid adapters, distinct classes, used to prove precedence: the
# convention sibling of AsyncConv::Override::Storage, and an explicitly
# registered override target. Both inherit the seams above.
{
  package AsyncConv::Override::Storage::Async;   # convention sibling
  use base 'AsyncConv::WithAdapter::Storage::Async';
}
{
  package AsyncConv::ExplicitAdapter;            # explicit-registration target
  use base 'AsyncConv::WithAdapter::Storage::Async';
}

# --- Driver storage classes (subclass the mock storage) --------------------
# ref($storage) is what the convention derives ::Async from. Subclassing
# DBIO::Test::Storage reuses its no-dbh / driver-determined / schema wiring.
{
  package AsyncConv::WithAdapter::Storage;   # has AsyncConv::WithAdapter::Storage::Async
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
{
  package AsyncConv::NoAdapter::Storage;      # NO ::Async sibling exists
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
{
  package AsyncConv::Override::Storage;        # has a convention sibling AND an explicit reg
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
{
  package AsyncConv::BaseReg::Storage;         # NO ::Async sibling; used with a base-class reg
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}

# Build a driver storage of $class in future_io mode, bound to a live schema.
# Returns ($storage, $schema) -- the caller must keep $schema alive (the async
# backend weakens its schema ref).
sub driver_storage {
  my ($class) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $storage = $class->new($schema);
  $storage->_async_mode('future_io');       # Test::Storage defaults to 'immediate'
  delete $storage->{_async_storage_obj};
  $storage->_connect_info([ { host => 'localhost' } ]);
  return ($storage, $schema);
}

# ---------------------------------------------------------------------------
# 1. WITH a convention ::Async adapter: future_io resolves it + CRUD roundtrip
# ---------------------------------------------------------------------------
{
  my ($storage, $schema) = driver_storage('AsyncConv::WithAdapter::Storage');

  my $async = $storage->async;
  isa_ok $async, 'AsyncConv::WithAdapter::Storage::Async',
    'future_io resolved the convention adapter (ref($storage)::Async)';
  isa_ok $async, 'DBIO::Storage::Async',
    '... which is a DBIO::Storage::Async';
  is $storage->_async_storage, $async,
    'the same adapter feeds the *_async CRUD dispatch (cached)';

  $async->{next_rows} = [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ] ];
  my $f = $storage->select_async('artist', [ 'artistid', 'name' ], { name => { -like => '%' } });
  isa_ok $f, 'AsyncConv::SyncFuture', 'select_async returns the adapter Future';
  is_deeply [ $f->get ], [ [ 1, 'Miles Davis' ], [ 2, 'John Coltrane' ] ],
    'select_async round-trips rows through the convention adapter';
  like $async->_last_sql, qr/^SELECT .*FROM "artist"/,
    'real DBIO::SQLMaker SQL was emitted through the adapter';

  # a write op round-trips too
  $async->{next_rows} = [];
  my $uf = $storage->update_async('artist', { name => 'X' }, { artistid => 1 });
  ok $uf->is_ready, 'update_async resolves through the convention adapter';
  like $async->_last_sql, qr/^UPDATE "artist" SET/, 'update_async emitted UPDATE SQL';
}

# ---------------------------------------------------------------------------
# 2. WITHOUT a convention ::Async adapter: EARLY, CLEAR croak
# ---------------------------------------------------------------------------
{
  my ($storage) = driver_storage('AsyncConv::NoAdapter::Storage');

  throws_ok { $storage->async }
    qr/\Qdriver AsyncConv::NoAdapter::Storage does not support future_io -- no AsyncConv::NoAdapter::Storage::Async\E/,
    'a driver without a convention ::Async adapter croaks early, naming the missing adapter';

  # the same early croak surfaces through a *_async op (not a late, opaque
  # "must override _submit_query" from an abstract base)
  my ($s2) = driver_storage('AsyncConv::NoAdapter::Storage');
  throws_ok { $s2->select_async('artist', [ '*' ], {}) }
    qr/does not support future_io/,
    'the early convention croak surfaces through select_async too';
}

# ---------------------------------------------------------------------------
# 3. Precedence: an EXPLICIT per-driver registration overrides the convention
# ---------------------------------------------------------------------------
{
  # AsyncConv::Override::Storage has a valid convention sibling, but an explicit
  # per-driver registration must win.
  AsyncConv::Override::Storage->register_async_mode(future_io => 'AsyncConv::ExplicitAdapter');

  my ($storage) = driver_storage('AsyncConv::Override::Storage');
  my $async = $storage->async;

  isa_ok $async, 'AsyncConv::ExplicitAdapter',
    'an explicit per-driver future_io registration wins over the convention';
  isnt ref($async), 'AsyncConv::Override::Storage::Async',
    '... the convention sibling is NOT used when an explicit registration exists';
}

# ---------------------------------------------------------------------------
# 4. A GENERIC base-class future_io registration must NOT satisfy future_io
#    (this is the bug the refinement fixes: loading an async dist used to
#    register future_io => DBIO::Async::Storage on the core base and "resolve"
#    the abstract base on any driver). Registered here on the base, a driver
#    WITHOUT a convention adapter must still croak.
# ---------------------------------------------------------------------------
{
  DBIO::Storage::DBI->register_async_mode(future_io => 'AsyncConv::ExplicitAdapter');

  my ($storage) = driver_storage('AsyncConv::BaseReg::Storage');
  throws_ok { $storage->async }
    qr/\QAsyncConv::BaseReg::Storage does not support future_io\E/,
    'a generic base-class future_io registration is ignored -- convention is still required';
}

done_testing;
