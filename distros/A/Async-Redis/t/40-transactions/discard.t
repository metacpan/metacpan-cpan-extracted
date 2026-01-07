# t/40-transactions/discard.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Cleanup
    run { $redis->del('discard:key') };

    subtest 'DISCARD aborts transaction' => sub {
        run { $redis->set('discard:key', 'original') };

        run { $redis->multi_start() };
        run { $redis->command('SET', 'discard:key', 'modified') };
        run { $redis->command('INCR', 'discard:key') };  # Would fail on string
        run { $redis->discard() };

        # Value should be unchanged
        my $value = run { $redis->get('discard:key') };
        is($value, 'original', 'value unchanged after DISCARD');
    };

    subtest 'commands work after DISCARD' => sub {
        run { $redis->multi_start() };
        run { $redis->discard() };

        # Should be able to use connection normally
        my $result = run { $redis->set('discard:key', 'after_discard') };
        is($result, 'OK', 'command works after DISCARD');

        my $value = run { $redis->get('discard:key') };
        is($value, 'after_discard', 'value set correctly');
    };

    subtest 'DISCARD preserves WATCH' => sub {
        run { $redis->set('discard:key', 'watched') };

        run { $redis->watch('discard:key') };
        run { $redis->multi_start() };
        run { $redis->command('SET', 'discard:key', 'in_tx') };
        run { $redis->discard() };

        # Watch should still be active
        ok($redis->watching, 'still watching after DISCARD');

        # Clear watch
        run { $redis->unwatch() };
        ok(!$redis->watching, 'not watching after UNWATCH');
    };

    subtest 'in_multi flag cleared after DISCARD' => sub {
        run { $redis->multi_start() };
        ok($redis->in_multi, 'in_multi true during transaction');

        run { $redis->discard() };
        ok(!$redis->in_multi, 'in_multi false after DISCARD');
    };

    # Cleanup
    run { $redis->del('discard:key') };
}

done_testing;
