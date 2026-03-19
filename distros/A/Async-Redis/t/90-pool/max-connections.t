# t/90-pool/max-connections.t
#
# Test that pool never exceeds max connections, even under concurrent acquire
#
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis::Pool;
use Future;

SKIP: {
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

    subtest 'concurrent acquires do not exceed max' => sub {
        my $pool = Async::Redis::Pool->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            min             => 0,
            max             => 2,
            acquire_timeout => 5,
        );

        # Fire 4 concurrent acquires against a pool with max=2
        # Two should get connections, two should wait
        my @futures = map { $pool->acquire } (1..4);

        # The first two should resolve (connections created)
        # Give them a moment to complete
        my @first_two;
        eval {
            @first_two = await_f(Future->wait_all(@futures[0,1]));
        };

        # Check total connections never exceeds max
        my $stats = $pool->stats;
        my $total = $stats->{active} + $stats->{idle};
        ok($total <= 2, "total connections ($total) does not exceed max (2)")
            or diag "stats: active=$stats->{active}, idle=$stats->{idle}";

        # Release connections so waiters can proceed
        for my $f (@futures) {
            if ($f->is_done) {
                my ($conn) = $f->get;
                $pool->release($conn);
            }
        }

        # Now let remaining futures complete
        eval {
            for my $f (@futures) {
                next if $f->is_ready;
                my $conn = await_f($f);
                $pool->release($conn);
            }
        };

        $stats = $pool->stats;
        $total = $stats->{active} + $stats->{idle};
        ok($total <= 2, "total connections ($total) still within max (2) after all acquires");
    };

    subtest 'stats reflect pending creations in total' => sub {
        my $pool = Async::Redis::Pool->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            min  => 0,
            max  => 3,
        );

        # Acquire 3 connections serially
        my @conns;
        for (1..3) {
            push @conns, run { $pool->acquire };
        }

        my $stats = $pool->stats;
        is($stats->{active}, 3, '3 active connections');
        is($stats->{total}, 3, '3 total connections');

        # Release all
        $pool->release($_) for @conns;

        $stats = $pool->stats;
        is($stats->{idle}, 3, '3 idle after release');
    };
}

done_testing;
