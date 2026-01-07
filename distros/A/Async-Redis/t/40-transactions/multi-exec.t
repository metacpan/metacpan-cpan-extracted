# t/40-transactions/multi-exec.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Future::AsyncAwait;
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
    run { $redis->del('tx:counter', 'tx:updated', 'tx:hash') };

    subtest 'basic MULTI/EXEC with callback' => sub {
        my $results = await_f($redis->multi(async sub {
            my ($tx) = @_;
            $tx->set('tx:counter', '0');
            $tx->incr('tx:counter');
            $tx->incr('tx:counter');
            $tx->get('tx:counter');
        }));

        is(ref $results, 'ARRAY', 'results is array');
        is(scalar @$results, 4, 'four results');
        is($results->[0], 'OK', 'SET returned OK');
        is($results->[1], 1, 'first INCR returned 1');
        is($results->[2], 2, 'second INCR returned 2');
        is($results->[3], '2', 'GET returned 2');
    };

    subtest 'transaction is atomic' => sub {
        run { $redis->set('tx:counter', '100') };

        # Start a transaction
        my $results = await_f($redis->multi(async sub {
            my ($tx) = @_;
            $tx->incr('tx:counter');
            $tx->incr('tx:counter');
            $tx->incr('tx:counter');
        }));

        is($results, [101, 102, 103], 'all increments applied atomically');

        my $final = run { $redis->get('tx:counter') };
        is($final, '103', 'final value correct');
    };

    subtest 'empty transaction' => sub {
        my $results = await_f($redis->multi(async sub {
            my ($tx) = @_;
            # Queue nothing
        }));

        is($results, [], 'empty transaction returns empty array');
    };

    subtest 'transaction with mixed commands' => sub {
        run { $redis->del('tx:hash') };

        my $results = await_f($redis->multi(async sub {
            my ($tx) = @_;
            $tx->hset('tx:hash', 'field1', 'value1');
            $tx->hset('tx:hash', 'field2', 'value2');
            $tx->hgetall('tx:hash');
        }));

        is($results->[0], 1, 'first HSET added field');
        is($results->[1], 1, 'second HSET added field');
        # Note: HGETALL in transaction returns array, not hash (transformation happens outside)
        is(ref $results->[2], 'ARRAY', 'HGETALL returned array');
    };

    subtest 'non-blocking verification' => sub {
        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        # Run 20 transactions
        for my $i (1..20) {
            await_f($redis->multi(async sub {
                my ($tx) = @_;
                $tx->set("tx:nb:$i", $i);
                $tx->incr("tx:nb:$i");
            }));
        }

        $timer->stop;
        get_loop()->remove($timer);

        ok(@ticks >= 2, "Event loop ticked during transactions");

        # Cleanup
        run { $redis->del(map { "tx:nb:$_" } 1..20) };
    };

    # Cleanup
    run { $redis->del('tx:counter', 'tx:updated', 'tx:hash') };
}

done_testing;
