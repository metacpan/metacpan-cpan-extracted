use strict;
use warnings;

use Test::More;

use DBIO::AccessBroker;
use DBIO::Async::Storage;

# --- Test broker: a minimal DBIO::AccessBroker that counts calls ---

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
        host => 'localhost',
        user => 'broker_user_' . $self->{calls},
      },
      {},
    ];
  }
}

# --- Test storage: provides seam hooks with trivial overrides ---
# (broker wiring doesn't execute queries, so only the conninfo and
# pool-creation hooks are needed)

{
  package TestStorage2;
  use base 'DBIO::Async::Storage';

  sub sql_maker_class        { 'DBIO::SQLMaker' }
  sub _transform_sql         { $_[1] }
  sub _post_insert_sql       { '' }
  sub _normalize_conninfo    { $_[1] }
  sub _create_pool_connection { bless {}, 'FakeConn' }
  sub _shutdown_pool_connection { }
  sub _conn_ready            { 1 }
  sub _txn_context_class     { 'DBIO::Async::TransactionContext' }
  sub _txn_conn_accessor     { 'txn_conn' }
  sub _pipeline_enter        { }
  sub _pipeline_sync         { Future->done }
  sub _pipeline_exit         { }
}

my $broker = TestBroker->new;
my $storage = TestStorage2->new(undef);

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

done_testing;
