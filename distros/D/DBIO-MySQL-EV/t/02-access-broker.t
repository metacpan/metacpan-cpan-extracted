use strict;
use warnings;

use Test::More;

use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::MySQL::EV;
use DBIO::MySQL::EV::Storage;

{
  package TestBroker;
  use base 'DBIO::AccessBroker';

  sub new {
    my $class = shift;
    bless {
      calls   => 0,
      refresh => 0,
    }, $class;
  }

  sub refresh { $_[0]->{refresh}++ }

  sub needs_refresh { $_[0]->{refresh} > 0 }

  sub connect_info_for_storage {
    my ($self, $storage, $mode) = @_;
    $self->{calls}++;

    return [
      {
        host     => 'localhost',
        database => 'dbio_async',
        user     => 'broker_user_' . $self->{calls},
      },
      {},
    ];
  }
}

my $broker = TestBroker->new;
my $storage = DBIO::MySQL::EV::Storage->new(undef);

$storage->connect_info([$broker]);

is $storage->access_broker, $broker, 'async storage keeps broker';
is $storage->access_broker_mode, 'write', 'async storage defaults broker mode to write';

my $info1 = $storage->_current_async_connect_info('write');
is $info1->[0]{user}, 'broker_user_2', 'first explicit async connect info comes from broker';

$broker->refresh;
my $info2 = $storage->_current_async_connect_info('write');
is $info2->[0]{user}, 'broker_user_3', 'fresh async connect info is fetched again from broker';

my $provider = $storage->_conninfo_provider;
is ref $provider, 'CODE', 'storage exposes broker-aware conninfo provider';
is $provider->()->{user}, 'broker_user_4', 'provider fetches fresh conninfo for new pool connections';

# Nail the adoption of the core-lifted async AccessBroker mechanics:
# the inherited _setup_access_broker installs a provider that drives the
# driver's _async_broker_conninfo hook, which must return one fresh,
# normalized EV::MariaDB conninfo hashref.
subtest 'driver consumes inherited async AccessBroker hook' => sub {
  plan tests => 3;

  my $hook = $storage->_async_broker_conninfo('write');
  is ref $hook, 'HASH', '_async_broker_conninfo returns a normalized conninfo hashref';
  is $hook->{user}, 'broker_user_5', 'hook fetches fresh conninfo from the broker';

  # The wired pool provider IS the inherited closure that calls the hook,
  # so its output and a direct hook call advance the broker in lockstep.
  is $storage->_conninfo_provider->()->{user}, 'broker_user_6',
    'inherited provider delegates to _async_broker_conninfo for each spawn';
};

{
  # karr #14 (ADR 0030): loading the MySQL::EV component is an INERT
  # marker — it no longer hijacks `connection()` to force
  # storage_type('+DBIO::MySQL::EV::Storage'). The async EV storage is
  # reached via the new opt-in at connect time:
  #
  #   MyApp::Schema->connect($dsn, $u, $p, { async => 'ev' })
  #
  # That `async => 'ev'` resolution is registered in DBIO::MySQL::Storage
  # (the sync driver) — its own karr ticket on the dbio-mysql board. Until
  # that lands, the schema->connect($broker) path here can no longer be
  # exercised through TestSchema (no async mode resolves to EV::Storage on
  # a schema that only loaded MySQL::EV). Construct the EV::Storage
  # directly to keep the broker-wiring assertions honest; the
  # schema->connect($broker, { async => 'ev' }) contract is covered by
  # the dbio-mysql board's karr ticket.
  package TestSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::EV');
}

my $ev_storage = DBIO::MySQL::EV::Storage->new(undef);
$ev_storage->connect_info([$broker]);
is $ev_storage->access_broker, $broker, 'async storage keeps broker';
is $ev_storage->access_broker_mode, 'write', 'async storage defaults broker mode to write';

subtest 'Static broker hashref works with EV::MariaDB conninfo' => sub {
  plan tests => 5;

  my $broker = DBIO::AccessBroker::Static->new(
    host     => '127.0.0.1',
    port     => 3306,
    dbname   => 'mydb',
    username => 'testuser',
    password => 'testpass',
  );

  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  $storage->connect_info([$broker]);

  ok($storage->access_broker, 'broker attached');
  my $conninfo = $storage->_conninfo_hash;
  is($conninfo->{host}, '127.0.0.1', 'host present in conninfo');
  is($conninfo->{port}, 3306, 'port present in conninfo');
  is($conninfo->{database}, 'mydb', 'database present in conninfo');
  is($conninfo->{user}, 'testuser', 'user present in conninfo');
};

done_testing;