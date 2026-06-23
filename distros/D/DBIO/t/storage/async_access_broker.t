# ABSTRACT: Storage::Async AccessBroker consumption seam (mock only, no real DB)
use strict;
use warnings;

use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# A rotating credential source: each call yields a freshly-numbered
# storage-native conninfo hashref, so we can prove the pool pulls fresh
# credentials per spawn rather than reusing a snapshot.
{
  package TestBroker;
  use base 'DBIO::AccessBroker';

  sub new { bless { calls => 0 }, shift }

  # Async storages call current_connect_info_for_storage, which routes
  # through connect_info_for_storage. Return storage-native shape.
  sub connect_info_for_storage {
    my ($self, $storage, $mode) = @_;
    my $n = ++$self->{calls};
    return { dbname => 'app', user => "user_$n" };
  }
}

# Minimal mock pool: records the (transformed) conninfo it built each
# connection from, and never touches a real database.
{
  package MockPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    push @{ $self->{_built_from} ||= [] }, $conninfo;
    return bless { conninfo => $conninfo }, 'MockConn';
  }

  # Echo the storage-native value through unchanged so the test can read
  # exactly what the provider handed the pool per spawn.
  sub _transform_conninfo { $_[1] }
}

# Minimal async storage consuming the lifted seam. It supplies only the
# driver-specific seam hook (_async_broker_conninfo) and a pool that wires
# in the inherited _conninfo_provider.
{
  package MockAsyncStorage;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    bless { schema => $schema, _conninfo_provider => undef }, $class;
  }

  sub future_class { 'Future' }

  sub connect_info {
    my ($self, $info) = @_;
    if ($info) {
      $self->{connect_info} = $info;
      if ($self->_is_access_broker_connect_info($info)) {
        $self->_setup_access_broker($info->[0]);
      }
      else {
        $self->_clear_access_broker;
        $self->{_static_conninfo} = $info;
      }
    }
    return $self->{connect_info};
  }

  # The one storage-native seam hook: one fresh conninfo value per spawn.
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    return $self->current_access_broker_connect_info($mode);
  }

  sub pool {
    my $self = shift;
    $self->{pool} ||= do {
      my %args = (size => 5);
      if (my $provider = $self->_conninfo_provider) {
        $args{conninfo_provider} = $provider;
      }
      else {
        $args{conninfo} = $self->{_static_conninfo};
      }
      MockPool->new(%args);
    };
  }
}

# --- broker detection is inherited ---

my $storage = MockAsyncStorage->new(undef);
ok $storage->_is_access_broker_connect_info([ TestBroker->new ]),
  'single-element arrayref of a broker is detected';
ok !$storage->_is_access_broker_connect_info(['dbi:Pg:dbname=app']),
  'plain connect info is not a broker';
ok !$storage->_is_access_broker_connect_info([ TestBroker->new, {} ]),
  'two-element arrayref is not a broker invocation';

# --- wiring a broker installs the per-spawn provider ---

my $broker = TestBroker->new;
$storage->connect_info([ $broker ]);

is $storage->access_broker, $broker, 'broker attached via inherited set_access_broker';
ok $storage->_conninfo_provider, 'conninfo_provider installed by _setup_access_broker';
is ref($storage->_conninfo_provider), 'CODE', 'provider is a coderef';

# --- every NEW pool connection gets fresh credentials ---

my $pool = $storage->pool;
isa_ok $pool, 'DBIO::Storage::PoolBase', 'pool';

my $c1 = $pool->acquire->get;
my $c2 = $pool->acquire->get;
my $c3 = $pool->acquire->get;

is_deeply $c1->{conninfo}, { dbname => 'app', user => 'user_1' },
  'first spawn pulled fresh credentials via the inherited seam';
is_deeply $c2->{conninfo}, { dbname => 'app', user => 'user_2' },
  'second spawn pulled freshly-refreshed credentials';
is_deeply $c3->{conninfo}, { dbname => 'app', user => 'user_3' },
  'third spawn pulled freshly-refreshed credentials again';

is $broker->{calls}, 3, 'broker consulted once per pool spawn, not snapshotted';

# --- detaching the broker tears the provider down ---

my $plain = MockAsyncStorage->new(undef);
$plain->connect_info([ $broker ]);
ok $plain->_conninfo_provider, 'provider present while broker attached';
$plain->connect_info(['dbi:Pg:dbname=app']);
ok !$plain->access_broker, 'broker cleared on non-broker connect_info';
ok !$plain->_conninfo_provider, 'provider torn down on non-broker connect_info';

# --- the seam hook is required when a driver does not override it ---

{
  package BareAsync;
  use base 'DBIO::Storage::Async';
  sub future_class { 'Future' }
}
my $bare = bless {}, 'BareAsync';
eval { $bare->_async_broker_conninfo('write') };
like $@, qr/Subclass must override _async_broker_conninfo/,
  '_async_broker_conninfo croaks until a driver implements it';

done_testing;
