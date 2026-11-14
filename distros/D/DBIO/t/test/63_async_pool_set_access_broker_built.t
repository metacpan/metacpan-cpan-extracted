# ABSTRACT: k331 (4): set_access_broker after the pool is built -- the pool follows the broker attached last
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(blessed);

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;

# karr k331 finding 4, decided by the maintainer (option A, mirror of k293):
# a broker attached after the pool was built is followed by that pool -- its
# next connection is opened from the broker attached last. What is open stays
# open (nothing is torn down).
#
# The notes below describe the state BEFORE the fix, where the measurement
# was taken.
#
# The question: the pool of an async backend is already built (one connection
# open). Then a broker B is attached with set_access_broker -- (i) on the
# async storage itself, (ii) on the sync storage that owns the backend. Which
# broker does the NEXT pool connection ask: A (the one before), B, or the
# static conninfo?
#
# Where the answer is decided:
#   lib/DBIO/Storage/Async.pm  set_access_broker  (~l.390): installs a NEW
#       provider closure and deletes _conninfo, but the pool is not touched.
#       A pool built through connect_info holds the OLD closure
#       (PoolBase conninfo_provider, PoolBase.pm ~l.1520). That closure reads
#       $storage->access_broker at call time, so it answers for B.
#       A pool built from static conninfo holds that conninfo by value
#       (PoolBase.pm ~l.1522) and never sees B.
#   lib/DBIO/Storage.pm  set_access_broker (~l.94): the broker slot of the
#       SYNC storage only. Nothing reaches {_async_storage_obj}
#       (DBIO::Storage::DBI::AccessBroker::clear_access_broker does that for
#       the detach, there is no counterpart for the attach), so the backend
#       keeps broker A in its own slot and keeps asking it.
#
# A broker that counts its answers; B's answers carry another dbname.
{
  package T63::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $name) = @_; bless { name => $name, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    $self->{calls}++;
    return { dbname => "db-$self->{name}", user => "user-$self->{name}" };
  }
}

{
  package T63::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { my ($self, $conninfo) = @_; push @{ $self->{built} }, $conninfo; bless {}, 'T63::Conn' }
  sub _transform_conninfo { $_[1] }
}

{
  package T63::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T63::Pool->new(
      size         => 3,
      future_class => $self->future_class,
      ($self->_conninfo_provider
        ? (conninfo_provider => $self->_conninfo_provider)
        : (conninfo          => $self->{_conninfo})),
    );
  }
}

{
  package T63::Driver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeK331 => __PACKAGE__);
  __PACKAGE__->register_async_mode(k331 => 'T63::Backend');
}

# Open one more pool connection; the conninfo it was built from.
sub next_conninfo {
  my ($backend) = @_;
  my $pool = $backend->pool;
  my $before = @{ $pool->{built} || [] };
  my $f = $pool->acquire;
  my @all = @{ $pool->{built} || [] };
  return @all > $before
    ? $all[-1]
    : ($f->is_failed ? 'FAILED: ' . $f->{values}[0] : 'nothing built');
}

# ---------------------------------------------------------------------------
# (i-a) async storage, pool built through broker A, then B attached directly.
# ---------------------------------------------------------------------------
{
  my ($A, $B) = (T63::Broker->new('A'), T63::Broker->new('B'));
  my $backend = T63::Backend->new(undef);
  $backend->connect_info([ $A ]);
  is_deeply next_conninfo($backend), { dbname => 'db-A', user => 'user-A' },
    '(i-a) pool built through broker A: first connection comes from A (control)';
  # connect_info itself reads the answer once (pool size), the spawn once more
  my $a_calls = $A->{calls};

  $backend->set_access_broker($B);
  my $conninfo = next_conninfo($backend);

  # IST-STAND k331 (4): the pool keeps the provider closure it was built with;
  # that closure reads the storage's CURRENT broker, so the follow-up
  # connection is asked of B and A is no longer asked. Maintainer-Entscheidung
  # offen: whether this is intended (a pool follows its storage's broker) or
  # incidental.
  is_deeply $conninfo, { dbname => 'db-B', user => 'user-B' },
    '(4) (i-a): after set_access_broker(B) the built pool\'s next connection is opened from B';
  is $A->{calls}, $a_calls, '... A is not asked again';
  is $B->{calls}, 1, '... B is asked once';
}

# ---------------------------------------------------------------------------
# (i-b) async storage, pool built from STATIC conninfo, then B attached.
# ---------------------------------------------------------------------------
{
  my $B = T63::Broker->new('B');
  my $backend = T63::Backend->new(undef);
  $backend->connect_info([ { dbname => 'db-static', user => 'user-static' } ]);
  is_deeply next_conninfo($backend), { dbname => 'db-static', user => 'user-static' },
    '(i-b) pool built from static connect info: first connection from it (control)';

  $backend->set_access_broker($B);
  ok defined $backend->_conninfo_provider && !defined $backend->{_conninfo},
    '... set_access_broker(B) installs the provider and drops the stored conninfo on the storage';
  my $conninfo = next_conninfo($backend);

  # k331 (4): the built pool is handed the provider and drops the static
  # conninfo, so B answers for its next connection.
  is_deeply $conninfo, { dbname => 'db-B', user => 'user-B' },
    '(4) (i-b): the built pool\'s next connection is opened from B, not the static conninfo';
  is $B->{calls}, 1, '... B is asked once';
  ok !exists $backend->pool->{conninfo}, '... the pool no longer holds the static conninfo';
  is scalar(@{ $backend->pool->{_connections} }), 2,
    '... the connection opened before is still there (nothing torn down)';
}

# ---------------------------------------------------------------------------
# (ii-a) sync storage owning a backend; backend pool built through A; then
# B attached to the SYNC storage.
# ---------------------------------------------------------------------------
sub owner {
  my @info = @_;
  my $schema = DBIO::Test->init_schema(no_connect => 1, storage_type => '+T63::Driver::Storage');
  $schema->connection(@info);
  return ($schema, $schema->storage);
}

{
  my ($A, $B) = (T63::Broker->new('A'), T63::Broker->new('B'));
  my ($schema, $storage) = owner($A, { async => 'k331' });
  my $backend = $storage->async;
  isa_ok $backend, 'T63::Backend', '(ii-a) the sync storage\'s backend';
  is_deeply next_conninfo($backend), { dbname => 'db-A', user => 'user-A' }, '... first connection from A (control)';
  my $a_calls = $A->{calls};

  $storage->set_access_broker($B);
  is $storage->access_broker, $B, '... set_access_broker(B) on the sync storage: its slot holds B';

  # k331 (4): the attach reaches the built backend, whose pool follows B.
  is $backend->access_broker, $B,
    '(4) (ii-a): the embedded backend holds broker B';
  is $storage->async, $backend, '... and is still the storage\'s backend (not rebuilt)';
  is_deeply next_conninfo($backend), { dbname => 'db-B', user => 'user-B' },
    '... its next pool connection is opened from B';
  is $A->{calls}, $a_calls, '... A is not asked again';
  is $B->{calls}, 1, '... B is asked once';
}

# ---------------------------------------------------------------------------
# (ii-b) sync storage with static connect info + backend pool built; then B
# attached to the sync storage.
# ---------------------------------------------------------------------------
{
  my $B = T63::Broker->new('B');
  my ($schema, $storage) = owner('dbi:FakeK331:dbname=static', 'static-user', 'static-pw', { async => 'k331' });
  my $backend = $storage->async;
  is_deeply next_conninfo($backend), 'dbi:FakeK331:dbname=static', '(ii-b) static backend: first connection from the DSN (control)';

  $storage->set_access_broker($B);
  is $backend->access_broker, $B, '... set_access_broker(B) on the sync storage: the backend holds B too';

  # k331 (4): same as (ii-a); the pool built from the static DSN follows B.
  is_deeply next_conninfo($backend), { dbname => 'db-B', user => 'user-B' },
    '(4) (ii-b): the backend\'s next connection comes from B, not the static DSN';
  is $B->{calls}, 1, '... B is asked once';
}

# ---------------------------------------------------------------------------
# (iii) sync storage, backend NOT built yet: nothing to pass on, no backend is
# built by the attach; the pool of the later backend is made from B.
# ---------------------------------------------------------------------------
{
  my $B = T63::Broker->new('B');
  my ($schema, $storage) = owner('dbi:FakeK331:dbname=static', 'u', 'p', { async => 'k331' });
  ok !$storage->{_async_storage_obj}, '(iii) no backend built yet';
  $storage->set_access_broker($B);
  ok !$storage->{_async_storage_obj}, '... the attach builds none';
  is $storage->access_broker, $B, '... the broker slot of the sync storage holds B';
}

# ---------------------------------------------------------------------------
# (iv) a pool type without the setter, and a backend whose pool was never
# built: the attach is not disturbed.
# ---------------------------------------------------------------------------
{
  my $B = T63::Broker->new('B');
  my $backend = T63::Backend->new(undef);
  $backend->connect_info([ { dbname => 'db-static' } ]);
  ok !$backend->{pool}, '(iv) pool not built';
  $backend->set_access_broker($B);
  is_deeply next_conninfo($backend), { dbname => 'db-B', user => 'user-B' },
    '... the pool built after the attach is made from B';

  $backend->{pool} = bless { conninfo => 'x' }, 'T63::OpaquePool';
  $backend->set_access_broker(T63::Broker->new('C'));
  is_deeply $backend->{pool}, { conninfo => 'x' },
    '... a pool without set_conninfo_provider is left as it is, the attach does not die';
  $backend->{pool} = undef;
}

done_testing;
