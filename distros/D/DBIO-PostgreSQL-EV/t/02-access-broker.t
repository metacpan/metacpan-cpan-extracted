use strict;
use warnings;

use Test::More;

use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::PostgreSQL::EV;
use DBIO::PostgreSQL::EV::Storage;

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
        dbname => 'dbio_async',
        host   => 'localhost',
        user   => 'broker_user_' . $self->{calls},
      },
      {},
    ];
  }
}

my $broker = TestBroker->new;
my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);

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

# A schema always declares its driver (core ADR 0067): TestSchema declares
# PostgreSQL with the shortcut, which pins storage_type to the sync
# DBIO::PostgreSQL::Storage and loads no component. PostgreSQL::EV is loaded
# after it as a component -- no driver component stands behind it that would
# set storage_type again, so a connection() hook or class data of
# DBIO::PostgreSQL::EV that chose a storage would show below.
{
  package TestSchema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL::EV');
}

# The schema connects with a broker that answers the DBI form.
{
  package DsnBroker;
  use base 'DBIO::AccessBroker';

  sub new { bless {}, shift }

  sub connect_info_for {
    return [ 'dbi:Pg:dbname=dbio_async;host=localhost', 'broker_user', undef, {} ];
  }
}

my $dsn_broker = DsnBroker->new;
my $schema = TestSchema->connect($dsn_broker);
# DBIO::PostgreSQL::EV is the distribution's overview module -- POD, no
# methods, no connection() hook -- so loading it as a component must NOT
# hijack storage_type to the async class. Async is a per-connection mode
# reached via { async => 'ev' } at connect (the 'ev' mode resolves to
# DBIO::PostgreSQL::EV::Storage via the sync DBIO::PostgreSQL::Storage's
# register_async_mode); this broker's answer carries no mode and the connect
# passes none, so the schema gets the sync driver it declared, while the
# broker still flows through connect_info.
is(TestSchema->storage_type, '+DBIO::PostgreSQL::Storage',
  'loading PostgreSQL::EV as a component leaves the declared storage_type alone');
isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage';
ok !$schema->storage->isa('DBIO::PostgreSQL::EV::Storage'),
  'loading PostgreSQL::EV as a component does not hijack storage_type to async';
is $schema->storage->access_broker, $dsn_broker, 'schema connect keeps broker';
is $schema->storage->access_broker_mode, 'write', 'schema connect defaults broker mode to write';

subtest 'Static broker hashref converts to libpq conninfo string correctly' => sub {
  plan tests => 6;

  # Use dev Storage directly (loaded at line 9 with lib/ in @INC taking precedence)
  my $broker = DBIO::AccessBroker::Static->new(
    host     => '127.0.0.1',
    port     => 5432,
    dbname   => 'mydb',
    username => 'testuser',
    password => 'testpass',
  );

  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([$broker]);

  ok($storage->access_broker, 'broker attached');
  my $conninfo = $storage->_conninfo_string;
  like($conninfo, qr/host=127\.0\.0\.1/, 'host present in conninfo');
  like($conninfo, qr/port=5432/, 'port present in conninfo');
  like($conninfo, qr/dbname=mydb/, 'dbname present in conninfo');
  like($conninfo, qr/user=testuser/, 'user present in conninfo');
  like($conninfo, qr/password=testpass/, 'password present in conninfo');
};

done_testing;
