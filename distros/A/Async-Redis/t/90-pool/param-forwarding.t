# t/90-pool/param-forwarding.t
#
# Test that Pool forwards all connection parameters to Async::Redis
#
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis::Pool;

SKIP: {
    # Verify Redis is available
    my $test_redis = eval {
        require Async::Redis;
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $test_redis;
    $test_redis->disconnect;

    subtest 'prefix is forwarded to pool connections' => sub {
        my $pool = Async::Redis::Pool->new(
            host   => $ENV{REDIS_HOST} // 'localhost',
            prefix => 'pooltest:',
            min    => 0,
            max    => 2,
        );

        my $conn = run { $pool->acquire };
        ok($conn, 'acquired connection');

        # Set a key through the pool connection — prefix should be applied
        run { $conn->set('mykey', 'prefixed_value') };

        # Verify the actual key in Redis has the prefix
        my $raw = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $raw->connect };

        my $val = run { $raw->get('pooltest:mykey') };
        is($val, 'prefixed_value', 'key was stored with prefix');

        # The prefixed connection should find it as 'mykey'
        my $prefixed_val = run { $conn->get('mykey') };
        is($prefixed_val, 'prefixed_value', 'prefixed get retrieves correctly');

        # Cleanup
        run { $raw->del('pooltest:mykey') };
        $raw->disconnect;
        $pool->release($conn);
    };

    subtest 'client_name is forwarded to pool connections' => sub {
        my $pool = Async::Redis::Pool->new(
            host        => $ENV{REDIS_HOST} // 'localhost',
            client_name => 'pool-test-client',
            min         => 0,
            max         => 2,
        );

        my $conn = run { $pool->acquire };
        ok($conn, 'acquired connection');

        # Verify client name was set
        my $name = run { $conn->command('CLIENT', 'GETNAME') };
        is($name, 'pool-test-client', 'client name forwarded');

        $pool->release($conn);
    };

    subtest 'username is forwarded for ACL auth' => sub {
        # This is a unit test — we verify the param is stored,
        # not that ACL auth works (would need a Redis with ACL configured)
        my $pool = Async::Redis::Pool->new(
            host     => $ENV{REDIS_HOST} // 'localhost',
            username => 'testuser',
            password => 'testpass',
            min      => 0,
            max      => 2,
        );

        # Verify pool stored the username
        ok(exists $pool->{_conn_args}{username}, 'username stored in conn args');
        is($pool->{_conn_args}{username}, 'testuser', 'username value correct');
    };

    subtest 'request_timeout is forwarded to pool connections' => sub {
        my $pool = Async::Redis::Pool->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            request_timeout => 42,
            min             => 0,
            max             => 2,
        );

        my $conn = run { $pool->acquire };
        ok($conn, 'acquired connection');

        is($conn->{request_timeout}, 42, 'request_timeout forwarded');

        $pool->release($conn);
    };
}

done_testing;
