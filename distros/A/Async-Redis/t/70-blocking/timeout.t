# t/70-blocking/timeout.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Time::HiRes qw(time);

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
            blocking_timeout_buffer => 2,  # 2 second buffer
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    subtest 'client timeout = server timeout + buffer' => sub {
        run { $redis->del('timeout:queue') };

        # BLPOP with 1 second server timeout
        # Client should wait 1 + 2 = 3 seconds before client-side timeout
        # But server returns first, so we get undef at ~1s

        my $start = time();
        my $result = run { $redis->blpop('timeout:queue', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'BLPOP returned undef');
        # Should be ~1 second (server timeout), not 3 (client timeout)
        ok($elapsed >= 0.9 && $elapsed < 2.0, "server timed out at ${elapsed}s");
    };

    subtest 'blocking_timeout_buffer prevents race condition' => sub {
        # The buffer ensures client doesn't timeout before server response arrives
        my $redis_short = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            blocking_timeout_buffer => 0.5,  # short buffer
        );
        run { $redis_short->connect };

        run { $redis_short->del('timeout:race') };

        my $start = time();
        my $result = run { $redis_short->blpop('timeout:race', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'returned undef');
        # Should still wait for server (~1s)
        ok($elapsed >= 0.9, "waited for server timeout (${elapsed}s)");
    };

    subtest 'BZPOPMIN timeout' => sub {
        run { $redis->del('timeout:zset') };

        my $start = time();
        my $result = run { $redis->bzpopmin('timeout:zset', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'BZPOPMIN returned undef on timeout');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s (${elapsed}s)");
    };

    subtest 'BZPOPMAX timeout' => sub {
        run { $redis->del('timeout:zset') };

        my $start = time();
        my $result = run { $redis->bzpopmax('timeout:zset', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'BZPOPMAX returned undef on timeout');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s (${elapsed}s)");
    };

    subtest 'BRPOPLPUSH timeout' => sub {
        run { $redis->del('timeout:src', 'timeout:dst') };

        my $start = time();
        my $result = run { $redis->brpoplpush('timeout:src', 'timeout:dst', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'BRPOPLPUSH returned undef on timeout');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s (${elapsed}s)");
    };
}

done_testing;
