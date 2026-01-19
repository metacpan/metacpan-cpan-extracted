# t/60-scripting/script-registry.t
# Tests for script registry operations
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis run);
use Test2::V0;
use Async::Redis;

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'list_scripts and get_script' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');

        # Initially empty
        my @scripts = $r->list_scripts;
        is(scalar @scripts, 0, 'no scripts initially');

        # Add scripts
        $r->define_command(script_a => { lua => 'return "a"' });
        $r->define_command(script_b => { lua => 'return "b"' });
        $r->define_command(script_c => { lua => 'return "c"' });

        @scripts = sort $r->list_scripts;
        is(\@scripts, ['script_a', 'script_b', 'script_c'], 'list_scripts returns all names');

        # Get individual scripts
        my $a = $r->get_script('script_a');
        ok($a, 'get_script returns script');
        is($a->name, 'script_a', 'script has correct name');

        my $missing = $r->get_script('nonexistent');
        is($missing, undef, 'get_script returns undef for missing');
    };

    subtest 'script replacement' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        # Define initial script (keys => 0 for no keys)
        $r->define_command(replaceable => { keys => 0, lua => 'return 1' });
        my $result = run { $r->run_script('replaceable') };
        is($result, 1, 'initial script returns 1');

        # Replace with new version
        $r->define_command(replaceable => { keys => 0, lua => 'return 2' });
        $result = run { $r->run_script('replaceable') };
        is($result, 2, 'replaced script returns 2');

        $r->disconnect;
    };

    subtest 'preload_scripts' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        # Clear any existing scripts from Redis
        run { $r->script_flush };

        # Define scripts
        my $script1 = $r->define_command(preload_a => {
            lua => 'return "preloaded_a"',
        });
        my $script2 = $r->define_command(preload_b => {
            lua => 'return "preloaded_b"',
        });

        # Scripts not loaded yet
        my $exists = run { $r->script_exists($script1->sha, $script2->sha) };
        is($exists, [0, 0], 'scripts not loaded initially');

        # Preload
        my $count = run { $r->preload_scripts };
        is($count, 2, 'preload_scripts returns count');

        # Now loaded
        $exists = run { $r->script_exists($script1->sha, $script2->sha) };
        is($exists, [1, 1], 'scripts loaded after preload');

        $r->disconnect;
    };

    subtest 'script accessors' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');

        my $script = $r->define_command(accessor_test => {
            keys        => 2,
            lua         => 'return KEYS[1] .. KEYS[2]',
            description => 'Test script for accessors',
        });

        is($script->name, 'accessor_test', 'name accessor');
        is($script->num_keys, 2, 'num_keys accessor');
        is($script->description, 'Test script for accessors', 'description accessor');
        like($script->sha, qr/^[a-f0-9]{40}$/, 'sha is 40 hex chars');
        like($script->script, qr/return KEYS/, 'script accessor returns lua code');
        # Use ref comparison to avoid deep comparison cycle
        ok($script->redis == $r, 'redis accessor returns connection');
    };

    subtest 'multiple redis instances have separate registries' => sub {
        my $r1 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        my $r2 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');

        $r1->define_command(only_in_r1 => { lua => 'return 1' });
        $r2->define_command(only_in_r2 => { lua => 'return 2' });

        ok($r1->get_script('only_in_r1'), 'r1 has only_in_r1');
        is($r1->get_script('only_in_r2'), undef, 'r1 does not have only_in_r2');

        ok($r2->get_script('only_in_r2'), 'r2 has only_in_r2');
        is($r2->get_script('only_in_r1'), undef, 'r2 does not have only_in_r1');
    };

    $redis->disconnect;
}

done_testing;
