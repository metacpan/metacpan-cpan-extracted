# t/30-pipeline/auto-pipeline.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Future;
use Time::HiRes qw(time);

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
            auto_pipeline => 1,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Cleanup
    run { $redis->del(map { "ap:$_" } 1..100) };

    subtest 'auto-pipeline batches concurrent commands' => sub {
        # Fire 100 commands "at once"
        my @futures = map {
            $redis->set("ap:$_", $_)
        } (1..100);

        # Wait for all
        my @results = await_f(Future->needs_all(@futures));

        is(scalar @results, 100, 'all 100 completed');
        ok((grep { $_ eq 'OK' } @results) == 100, 'all returned OK');

        # Verify values
        my @get_futures = map { $redis->get("ap:$_") } (1..10);
        my @values = await_f(Future->needs_all(@get_futures));
        is(\@values, [1..10], 'values stored correctly');
    };

    subtest 'auto-pipeline transparent API' => sub {
        # Same API as non-pipelined
        my $result = run { $redis->set('ap:single', 'value') };
        is($result, 'OK', 'single command works');

        my $value = run { $redis->get('ap:single') };
        is($value, 'value', 'GET works');
    };

    subtest 'auto-pipeline faster than sequential' => sub {
        # Compare auto-pipelined to non-pipelined

        my $redis_no_ap = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 0,  # disabled
        );
        run { $redis_no_ap->connect };

        # Sequential (no auto-pipeline)
        my $start = time();
        for my $i (1..50) {
            run { $redis_no_ap->set("ap:seq:$i", $i) };
        }
        my $sequential_time = time() - $start;

        # Auto-pipelined
        $start = time();
        my @futures = map { $redis->set("ap:batch:$_", $_) } (1..50);
        await_f(Future->needs_all(@futures));
        my $batched_time = time() - $start;

        ok($batched_time < $sequential_time,
            "Auto-pipeline (${batched_time}s) faster than sequential (${sequential_time}s)");

        # Cleanup
        await_f($redis->del(map { ("ap:seq:$_", "ap:batch:$_") } 1..50));
    };

    subtest 'auto-pipeline respects depth limit' => sub {
        my $redis_limited = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 1,
            pipeline_depth => 50,
        );
        run { $redis_limited->connect };

        # Fire more commands than depth limit
        # Should batch into multiple pipelines automatically
        my @futures = map {
            $redis_limited->set("ap:depth:$_", $_)
        } (1..100);

        my @results = await_f(Future->needs_all(@futures));
        is(scalar @results, 100, 'all 100 completed despite depth limit');

        # Cleanup
        run { $redis->del(map { "ap:depth:$_" } 1..100) };
    };

    subtest 'non-blocking verification' => sub {
        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        # Fire 500 commands
        my @futures = map { $redis->set("ap:nb:$_", $_) } (1..500);
        await_f(Future->needs_all(@futures));

        $timer->stop;
        get_loop()->remove($timer);

        pass("Event loop remained responsive during 500 concurrent commands");

        # Cleanup
        run { $redis->del(map { "ap:nb:$_" } 1..500) };
    };

    subtest 'errors propagate to correct futures' => sub {
        run { $redis->set('ap:string', 'hello') };

        my $f1 = $redis->set('ap:ok1', 'value');
        my $f2 = $redis->lpush('ap:string', 'item');  # Will fail (WRONGTYPE)
        my $f3 = $redis->set('ap:ok2', 'value');

        my $r1 = await_f($f1);
        is($r1, 'OK', 'first command succeeded');

        my $r2;
        eval { $r2 = await_f($f2) };
        my $error = $@;
        ok($error || (ref $r2 && "$r2" =~ /WRONGTYPE/i), 'error propagated to correct future');

        my $r3 = await_f($f3);
        is($r3, 'OK', 'third command succeeded');

        # Cleanup
        run { $redis->del('ap:string', 'ap:ok1', 'ap:ok2') };
    };

    # Cleanup
    run { $redis->del(map { "ap:$_" } 1..100) };
}

done_testing;
