use strict;
use warnings;

use Test::More;

use DBIO::AccessBroker;
use DBIO::AccessBroker::Credentials;
use DBIO::MySQL::Async;
use DBIO::MySQL::Async::Storage;

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
my $storage = DBIO::MySQL::Async::Storage->new(undef);

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
  package TestSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::Async');
}

my $schema = TestSchema->connect($broker);
isa_ok $schema->storage, 'DBIO::MySQL::Async::Storage';
is $schema->storage->access_broker, $broker, 'async schema connect keeps broker';
is $schema->storage->access_broker_mode, 'write', 'async schema connect defaults broker mode to write';

subtest 'Static broker hashref works with EV::MariaDB conninfo' => sub {
  plan tests => 5;

  my $broker = DBIO::AccessBroker::Credentials->new(
    host     => '127.0.0.1',
    port     => 3306,
    dbname   => 'mydb',
    user     => 'testuser',
    password => 'testpass',
  );

  my $storage = DBIO::MySQL::Async::Storage->new(undef);
  $storage->connect_info([$broker]);

  ok($storage->access_broker, 'broker attached');
  my $conninfo = $storage->_conninfo_hash;
  is($conninfo->{host}, '127.0.0.1', 'host present in conninfo');
  is($conninfo->{port}, 3306, 'port present in conninfo');
  is($conninfo->{database}, 'mydb', 'database present in conninfo');
  is($conninfo->{user}, 'testuser', 'user present in conninfo');
};

done_testing;