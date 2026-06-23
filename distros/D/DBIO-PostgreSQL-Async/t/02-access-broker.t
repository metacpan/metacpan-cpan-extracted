use strict;
use warnings;

use Test::More;

use DBIO::AccessBroker;
use DBIO::AccessBroker::Credentials;
use DBIO::PostgreSQL::Async;
use DBIO::PostgreSQL::Async::Storage;

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
my $storage = DBIO::PostgreSQL::Async::Storage->new(undef);

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

{
  package TestSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL::Async');
}

my $schema = TestSchema->connect($broker);
isa_ok $schema->storage, 'DBIO::PostgreSQL::Async::Storage';
is $schema->storage->access_broker, $broker, 'async schema connect keeps broker';
is $schema->storage->access_broker_mode, 'write', 'async schema connect defaults broker mode to write';

subtest 'Static broker hashref converts to libpq conninfo string correctly' => sub {
  plan tests => 6;

  # Use dev Storage directly (loaded at line 9 with lib/ in @INC taking precedence)
  my $broker = DBIO::AccessBroker::Credentials->new(
    host     => '127.0.0.1',
    port     => 5432,
    dbname   => 'mydb',
    user     => 'testuser',
    password => 'testpass',
  );

  my $storage = DBIO::PostgreSQL::Async::Storage->new(undef);
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
