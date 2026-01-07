# t/90-pool/basic.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis::Pool;
use Time::HiRes qw(time);

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

    subtest 'pool creation' => sub {
        my $pool = Async::Redis::Pool->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            min  => 2,
            max  => 5,
        );

        ok($pool, 'pool created');
        is($pool->min, 2, 'min connections');
        is($pool->max, 5, 'max connections');
    };

    subtest 'acquire and release' => sub {
        my $pool = Async::Redis::Pool->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            min  => 1,
            max  => 3,
        );

        my $conn = run { $pool->acquire };
        ok($conn, 'acquired connection');
        ok($conn->isa('Async::Redis'), 'connection is Redis object');

        # Use connection
        my $result = run { $conn->ping };
        is($result, 'PONG', 'connection works');

        # Release
        $pool->release($conn);

        my $stats = $pool->stats;
        is($stats->{idle}, 1, 'connection returned to pool');
        is($stats->{active}, 0, 'no active connections');
    };

    subtest 'acquire returns same connection' => sub {
        my $pool = Async::Redis::Pool->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            min  => 1,
            max  => 3,
        );

        my $conn1 = run { $pool->acquire };
        my $id1 = "$conn1";  # stringified address
        $pool->release($conn1);

        my $conn2 = run { $pool->acquire };
        my $id2 = "$conn2";

        is($id1, $id2, 'got same connection from pool');

        $pool->release($conn2);
    };

    subtest 'multiple acquires up to max' => sub {
        my $pool = Async::Redis::Pool->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            min  => 0,
            max  => 3,
        );

        my @conns;
        for my $i (1..3) {
            push @conns, run { $pool->acquire };
        }

        is(scalar @conns, 3, 'acquired max connections');

        my $stats = $pool->stats;
        is($stats->{active}, 3, '3 active connections');
        is($stats->{idle}, 0, '0 idle connections');
        is($stats->{total}, 3, '3 total connections');

        # Release all
        $pool->release($_) for @conns;

        $stats = $pool->stats;
        is($stats->{active}, 0, '0 active after release');
        is($stats->{idle}, 3, '3 idle after release');
    };

    subtest 'acquire blocks when pool exhausted' => sub {
        my $pool = Async::Redis::Pool->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            max             => 1,
            acquire_timeout => 1,
        );

        my $conn1 = run { $pool->acquire };

        # Second acquire should timeout
        my $start = time();
        my $error;
        eval {
            run { $pool->acquire };
        };
        $error = $@;
        my $elapsed = time() - $start;

        ok($error, 'acquire timed out');
        like("$error", qr/timeout|acquire/i, 'timeout error');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s ($elapsed)");

        $pool->release($conn1);
    };
}

done_testing;
