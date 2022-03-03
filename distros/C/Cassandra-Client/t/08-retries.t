#!perl
use 5.010;
use strict;
use warnings;
use File::Basename qw//; use lib File::Basename::dirname(__FILE__).'/lib';
use Test::More;
use Test::Exception;
use TestCassandra;
use Cassandra::Client::Policy::Retry::Default;
use InstrumentedRetry;
use Cassandra::Client::Error::ReadTimeoutException;

plan skip_all => "Missing Cassandra test environment" unless TestCassandra->is_ok;
plan tests => 10;

my $instrumented_retry = InstrumentedRetry->new(
    Cassandra::Client::Policy::Retry::Default->new(
         max_retries_write_timeout => 2,
    )
);

my $client= TestCassandra->new(
    retry_policy => $instrumented_retry,
    request_timeout => 6,
);

$client->connect();

# broken because not enough replicas
{
    my $keyspace = 'brokenreplicationspace';
    my $table = 'testtable';
    $client->execute("drop keyspace if exists $keyspace");
    local $SIG{__WARN__} = sub {
        my $warning = shift;
        ok(1) if $warning =~ qr/Aggregation query used without partition key at/;
    };
    my ($res) = $client->execute("SELECT * FROM system.peers");
    my $node_count = 1 + @{$res->rows};
    my $rf = $node_count + 1;   # this RF is certainly too big
    $client->execute("CREATE KEYSPACE $keyspace WITH REPLICATION = {'class':'SimpleStrategy', 'replication_factor': $rf}",{},{});
    $client->execute("CREATE TABLE $keyspace.$table (id int, PRIMARY KEY (id))");
    $instrumented_retry->reset();
    throws_ok
        { $client->execute("INSERT INTO $keyspace.$table (id) VALUES (1)",{},{consistency => 'all', idempotent => 1}); }
        qr/Error 4096: Cannot achieve consistency level ALL/,
        "Not enough replicas";
    is ($instrumented_retry->{counters}{on_unavailable}, 2, "One retry means two attempts");

}

# retry after a read timeout
{
    my $keyspace = 'timeoutspace';
    my $table = 'timeouttable';

    $client->execute("drop keyspace if exists $keyspace");
    $client->execute("CREATE KEYSPACE $keyspace WITH REPLICATION = {'class': 'SimpleStrategy', 'replication_factor': '1'}");
    $client->execute("CREATE TABLE $keyspace.$table (id int, a int, b int, c int, d int, e int, f int, PRIMARY KEY (id,a))");

    $client->execute("INSERT INTO $keyspace.$table (id, a, b, c, d, e, f) VALUES( 1, 1, 1, 1, 1, 1, 1)",{},{});

    $instrumented_retry->reset();
    my $read_error = Cassandra::Client::Error::ReadTimeoutException->new(
        code => 42,
        message => 'Synthetic read error',
        is_timeout => 1,
        received => 0,
        blockfor => 1,
        data_retrieved => 0,
   );

    throws_ok
        { (my $res) = $client->execute("SELECT * FROM $keyspace.$table",{},{_synthetic_error => $read_error}); }
        qr/Error 42: Synthetic read error/,
        "Read error for testing";

    is ($instrumented_retry->{counters}{on_read_timeout}, 2, "One retry means two attempts");


}

# retry after a write timeout

{
    my $keyspace = 'timeoutspace';
    my $table = 'timeouttable';
    my $udf_not_allowed = 0;

    local $SIG{__WARN__} = sub {
        my $warning = shift;
        like($warning, qr/Error 8704: User-defined functions are disabled in cassandra.yaml/, "UDFs are not allowed, test is partial.");
        $udf_not_allowed = 1;
    };

    $client->execute("CREATE OR REPLACE FUNCTION $keyspace.sleep (time int) CALLED ON NULL INPUT RETURNS int LANGUAGE java AS 'long start = System.currentTimeMillis();while (System.currentTimeMillis() < start + time); return time;'");

    SKIP: {
        skip "These tests use a UDF, but the Cassandra server does not allow them.", 6 if $udf_not_allowed;
        # Retry after an idempotent statement
        my $t0 = Time::HiRes::time();
        $instrumented_retry->reset();
        throws_ok
            { $client->execute("INSERT INTO $keyspace.$table (id, a, b, c, d, e, f) VALUES( 1, 1, sleep(450), sleep(450), sleep(450), sleep(450), sleep(450))",{},{idempotent => 1}); }
            qr/Error 4352: Operation timed out - received only 0 responses/,
            "Write timeout, the query is too slow";
        my $t = Time::HiRes::time() - $t0;
        # the retry policy will retry 2 times on write timeout. This means that the exception will be rethrown after 3 * 2000 millis
        # but not after more than 4 * 2000 millis  as this would mean more than 2 retry happened
        ok( $t > 6.0 and $t < 8.0) or diag("write retry once test took $t");
        is ($instrumented_retry->{counters}{on_write_timeout}, 3, "Two retries on idempotent write statements");

        # Do not retry a non idempotent statement
        $t0 = Time::HiRes::time();
        $instrumented_retry->reset();
        throws_ok
            { $client->execute("INSERT INTO $keyspace.$table (id, a, b, c, d, e, f) VALUES( 1, 1, sleep(450), sleep(450), sleep(450), sleep(450), sleep(450))",{},{idempotent => 0}); }
            qr/Error 4352: Operation timed out - received only 0 responses/,
            "Write timeout, the query is too slow and cannot be retried";
        $t = Time::HiRes::time() - $t0;
        # this took longer than one write timeout but less than two -> no retry happened
        ok( $t> 2.0 and $t < 4.0 ) or note("Write do not retry test took $t");
        is ($instrumented_retry->{counters}{on_write_timeout}, 1, "One attempt, no retries");
    }
}
