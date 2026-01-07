# t/70-blocking/concurrent.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Future;
use Async::Redis;
use Time::HiRes qw(time);

SKIP: {
    my $redis1 = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis1;

    # Second connection for concurrent operations
    my $redis2 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
    run { $redis2->connect };

    # Third connection for pushing data
    my $pusher = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
    run { $pusher->connect };

    subtest 'multiple concurrent BLPOP on different queues' => sub {
        run { $redis1->del('conc:q1', 'conc:q2') };

        # Start two BLPOP operations concurrently
        my $f1 = $redis1->blpop('conc:q1', 5);
        my $f2 = $redis2->blpop('conc:q2', 5);

        # Push to both after short delay
        run { get_loop()->delay_future(after => 0.2) };
        run { $pusher->rpush('conc:q1', 'item1') };
        run { $pusher->rpush('conc:q2', 'item2') };

        # Wait for both
        my @results = await_f(Future->needs_all($f1, $f2));

        is($results[0], ['conc:q1', 'item1'], 'first BLPOP got item');
        is($results[1], ['conc:q2', 'item2'], 'second BLPOP got item');

        # Cleanup
        run { $redis1->del('conc:q1', 'conc:q2') };
    };

    subtest 'multiple BLPOP waiters on same queue' => sub {
        run { $redis1->del('conc:shared') };

        # Two connections waiting on same queue
        my $f1 = $redis1->blpop('conc:shared', 5);
        my $f2 = $redis2->blpop('conc:shared', 5);

        # Small delay to ensure both are waiting
        run { get_loop()->delay_future(after => 0.1) };

        # Push two items so both waiters get something
        run { $pusher->rpush('conc:shared', 'item1', 'item2') };

        # Wait for both
        my @results = await_f(Future->needs_all($f1, $f2));

        # Both should get something (order depends on which connected first)
        ok(defined $results[0], 'first waiter got an item');
        ok(defined $results[1], 'second waiter got an item');

        # Items should be different
        isnt($results[0][1], $results[1][1], 'waiters got different items');

        # Cleanup
        run { $redis1->del('conc:shared') };
    };

    subtest 'non-blocking during concurrent waits' => sub {
        run { $redis1->del('conc:nb') };

        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        # Start concurrent BLPOP operations
        my $f1 = $redis1->blpop('conc:nb', 1);
        my $f2 = $redis2->blpop('conc:nb', 1);

        # Wait for both to timeout
        await_f(Future->needs_all($f1, $f2));

        $timer->stop;
        get_loop()->remove($timer);

        # Should tick throughout the concurrent waits
        ok(@ticks >= 50, "Event loop ticked " . scalar(@ticks) . " times during concurrent BLPOPs");
    };
}

done_testing;
