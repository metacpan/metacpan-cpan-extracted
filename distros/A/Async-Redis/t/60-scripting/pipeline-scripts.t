# t/60-scripting/pipeline-scripts.t
# Tests for script integration with pipelines
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis run cleanup_keys);
use Test2::V0;
use Async::Redis;

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'run_script in pipeline' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        # Define a script
        $r->define_command(pipe_incr => {
            keys => 1,
            lua  => <<'LUA',
                local val = tonumber(redis.call('INCR', KEYS[1]))
                return val * tonumber(ARGV[1])
LUA
        });

        # Set up data
        run { $r->set('pipe:a', 0) };
        run { $r->set('pipe:b', 0) };

        # Use in pipeline
        my $pipe = $r->pipeline;
        $pipe->run_script('pipe_incr', 'pipe:a', 10);  # (0+1)*10 = 10
        $pipe->run_script('pipe_incr', 'pipe:b', 5);   # (0+1)*5 = 5
        $pipe->run_script('pipe_incr', 'pipe:a', 2);   # (1+1)*2 = 4

        my $results = run { $pipe->execute };
        is($results, [10, 5, 4], 'pipeline scripts return correct results');

        run { cleanup_keys($r, 'pipe:*') };
        $r->disconnect;
    };

    subtest 'mixed commands and scripts in pipeline' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        $r->define_command(double => {
            keys => 1,
            lua  => 'return tonumber(redis.call("GET", KEYS[1])) * 2',
        });

        my $pipe = $r->pipeline;
        $pipe->set('mix:val', 5);
        $pipe->run_script('double', 'mix:val');
        $pipe->get('mix:val');
        $pipe->incr('mix:val');
        $pipe->run_script('double', 'mix:val');

        my $results = run { $pipe->execute };
        is($results, ['OK', 10, '5', 6, 12], 'mixed pipeline works');

        run { cleanup_keys($r, 'mix:*') };
        $r->disconnect;
    };

    subtest 'dynamic key script in pipeline' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        $r->define_command(sum_keys => {
            keys => 'dynamic',
            lua  => <<'LUA',
                local sum = 0
                for i, key in ipairs(KEYS) do
                    sum = sum + tonumber(redis.call('GET', key) or 0)
                end
                return sum
LUA
        });

        run { $r->mset('sum:a', 10, 'sum:b', 20, 'sum:c', 30) };

        my $pipe = $r->pipeline;
        $pipe->run_script('sum_keys', 2, 'sum:a', 'sum:b');      # 30
        $pipe->run_script('sum_keys', 3, 'sum:a', 'sum:b', 'sum:c');  # 60
        $pipe->run_script('sum_keys', 1, 'sum:c');              # 30

        my $results = run { $pipe->execute };
        is($results, [30, 60, 30], 'dynamic key scripts in pipeline');

        run { cleanup_keys($r, 'sum:*') };
        $r->disconnect;
    };

    subtest 'same script multiple times (dedup loading)' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        # Clear scripts
        run { $r->script_flush };

        $r->define_command(counter => {
            keys => 1,
            lua  => 'return redis.call("INCR", KEYS[1])',
        });

        # Use same script many times
        my $pipe = $r->pipeline;
        for (1..10) {
            $pipe->run_script('counter', "dedup:key");
        }

        my $results = run { $pipe->execute };
        is($results, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 'same script 10 times works');

        run { cleanup_keys($r, 'dedup:*') };
        $r->disconnect;
    };

    subtest 'unknown script in pipeline error' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        my $pipe = $r->pipeline;
        $pipe->set('err:key', 'value');
        $pipe->run_script('not_defined', 'err:key');

        like(
            dies { run { $pipe->execute } },
            qr/Unknown script.*not_defined/,
            'pipeline dies on unknown script'
        );

        $r->disconnect;
    };

    subtest 'pipeline with script after script_flush' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        $r->define_command(simple_get => {
            keys => 1,
            lua  => 'return redis.call("GET", KEYS[1])',
        });

        run { $r->set('flush:key', 'flush:value') };

        # Flush all scripts from server
        run { $r->script_flush };

        # Pipeline should still work (preloads before execution)
        my $pipe = $r->pipeline;
        $pipe->run_script('simple_get', 'flush:key');

        my $results = run { $pipe->execute };
        is($results, ['flush:value'], 'pipeline works after script_flush');

        run { cleanup_keys($r, 'flush:*') };
        $r->disconnect;
    };

    $redis->disconnect;
}

done_testing;
