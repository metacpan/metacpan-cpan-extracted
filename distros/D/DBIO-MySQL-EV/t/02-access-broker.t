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

    # dbname, not database: one answer for both storages that ask this broker.
    # The transport reads it as EV::MariaDB's database; the schema's sync
    # storage builds its DSN from it, and refuses an answer naming no database
    # (core k271) -- it connects with a broker's credentials only to the
    # DSN the broker answers.
    return [
      {
        host   => 'localhost',
        dbname => 'dbio_async',
        user   => 'broker_user_' . $self->{calls},
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
  package TestSchema;
  use base 'DBIO::Schema';
  # The driver component declares the driver (core ADR 0059): a broker answers
  # connection parameters, not a DSN, and only a driver's own storage can build
  # the DSN from them -- the generic DBIO::Storage::DBI refuses. The marker
  # rides along, and is what this file asks about.
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
}

# karr k14 (ADR 0030 / ADR 0032 §7): loading the MySQL::EV component must NOT
# hijack storage_type to the async class — that hijack is exactly what k14 was.
# The component is a no-op marker; async is reached per connection with
# { async => 'ev' } at connect, and that mode is registered on the SYNC driver
# (DBIO::MySQL::Storage->register_async_mode(ev => ...), shipped in dbio-mysql
# since commit 8515206) — never here. Without the opt-in the schema therefore
# gets the driver's sync storage, while the broker still flows through
# connect_info. This mirrors dbio-postgresql-ev's t/02.
#
# The marker comes after the driver component in the schema's MRO, so a
# connection() hook on it would run after the driver's and its storage_type
# would win: the NEGATIVE assertion below — 'is not the EV storage' — still
# fails on a marker that pins one. (The marker loaded alone, with no driver,
# is held by t/00-load.t's storage_layer_contract_ok.) There is no database
# here: connect() only configures the storage, nothing is opened.
my $schema = TestSchema->connect($broker);
isa_ok $schema->storage, 'DBIO::MySQL::Storage';
ok !$schema->storage->isa('DBIO::MySQL::EV::Storage'),
  'loading MySQL::EV marker does not hijack storage_type to async';
is $schema->storage->access_broker, $broker, 'schema connect keeps broker';
is $schema->storage->access_broker_mode, 'write',
  'schema connect defaults broker mode to write';

# The EV transport also takes a broker directly (the form the README documents
# alongside the schema-level connect above).
my $ev_storage = DBIO::MySQL::EV::Storage->new(undef);
$ev_storage->connect_info([$broker]);
is $ev_storage->access_broker, $broker, 'async storage keeps broker';
is $ev_storage->access_broker_mode, 'write', 'async storage defaults broker mode to write';

subtest 'Static broker hashref works with EV::MariaDB conninfo' => sub {
  plan tests => 6;

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

  # The conninfo a connection is opened from is what the per-spawn provider
  # makes of the broker's answer at that moment. The storage keeps none of it
  # (karr k62): _conninfo_hash, the STORED conninfo, has nothing to return with
  # a broker attached -- a stored copy could only be the first answer, password
  # included, and is what a detached broker would otherwise fall back to.
  is($storage->_conninfo_hash, undef, 'no conninfo is stored from the broker\'s answer');
  my $conninfo = $storage->_conninfo_provider->();
  is($conninfo->{host}, '127.0.0.1', 'host present in conninfo');
  is($conninfo->{port}, 3306, 'port present in conninfo');
  is($conninfo->{database}, 'mydb', 'database present in conninfo');
  is($conninfo->{user}, 'testuser', 'user present in conninfo');
};

done_testing;