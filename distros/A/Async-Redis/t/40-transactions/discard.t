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

    my $redis2 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
    run { $redis2->connect };

    # Cleanup
    run { $redis->del('discard:key', 'discard:after_watch') };

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

    subtest 'DISCARD clears WATCH' => sub {
        run { $redis->set('discard:key', 'watched') };
        run { $redis->del('discard:after_watch') };

        run { $redis->watch('discard:key') };
        run { $redis->multi_start() };
        run { $redis->command('SET', 'discard:key', 'in_tx') };
        run { $redis->discard() };

        ok(!$redis->watching, 'not watching after DISCARD');

        # Prove Redis also cleared the server-side WATCH. If DISCARD leaked
        # the watch, this later transaction would abort after redis2 writes.
        run { $redis2->set('discard:key', 'changed') };
        run { $redis->multi_start() };
        run { $redis->command('SET', 'discard:after_watch', 'ok') };
        my $results = run { $redis->exec() };

        ok(defined $results, 'later transaction succeeds after DISCARD');
        is($results, ['OK'], 'later EXEC applies queued write');
    };

    subtest 'in_multi flag cleared after DISCARD' => sub {
        run { $redis->multi_start() };
        ok($redis->in_multi, 'in_multi true during transaction');

        run { $redis->discard() };
        ok(!$redis->in_multi, 'in_multi false after DISCARD');
    };

    # Cleanup
    run { $redis->del('discard:key', 'discard:after_watch') };
}

done_testing;
