# t/60-scripting/define-command.t
# Tests for define_command() and run_script()
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(skip_without_redis run cleanup_keys);
use Test2::V0;
use Async::Redis;

SKIP: {
    my $redis = skip_without_redis();

    subtest 'define_command with fixed keys' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        # Define a simple increment script
        my $script = $r->define_command(test_incr => {
            keys => 1,
            lua  => <<'LUA',
                local current = tonumber(redis.call('GET', KEYS[1]) or 0)
                local result = current + tonumber(ARGV[1])
                redis.call('SET', KEYS[1], result)
                return result
LUA
        });

        ok($script, 'define_command returns script object');
        is($script->name, 'test_incr', 'script has correct name');
        is($script->num_keys, 1, 'script has correct num_keys');

        # Run the script
        run { $r->set('script:counter', 10) };
        my $result = run { $r->run_script('test_incr', 'script:counter', 5) };
        is($result, 15, 'run_script returns correct result');

        my $val = run { $r->get('script:counter') };
        is($val, '15', 'script modified the key');

        run { cleanup_keys($r, 'script:*') };
        $r->disconnect;
    };

    subtest 'define_command with dynamic keys' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        # Define script with dynamic key count
        $r->define_command(multi_get => {
            keys => 'dynamic',
            lua  => <<'LUA',
                local results = {}
                for i, key in ipairs(KEYS) do
                    results[i] = redis.call('GET', key)
                end
                return results
LUA
        });

        # Set up test data
        run { $r->set('dyn:a', 'val_a') };
        run { $r->set('dyn:b', 'val_b') };
        run { $r->set('dyn:c', 'val_c') };

        # Run with 2 keys
        my $result = run { $r->run_script('multi_get', 2, 'dyn:a', 'dyn:b') };
        is($result, ['val_a', 'val_b'], 'dynamic script with 2 keys');

        # Run with 3 keys
        $result = run { $r->run_script('multi_get', 3, 'dyn:a', 'dyn:b', 'dyn:c') };
        is($result, ['val_a', 'val_b', 'val_c'], 'dynamic script with 3 keys');

        run { cleanup_keys($r, 'dyn:*') };
        $r->disconnect;
    };

    subtest 'define_command rejects install option' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        like(
            dies {
                $r->define_command(custom_set => {
                    keys    => 1,
                    lua     => 'return redis.call("SET", KEYS[1], ARGV[1])',
                    install => 1,
                });
            },
            qr/install option is not supported.*run_script/s,
            'dies with explicit run_script guidance',
        );

        ok(!$r->can('custom_set'), 'unsupported install does not create a method');
        is($r->get_script('custom_set'), undef, 'unsupported install does not register script');

        $r->disconnect;
    };

    subtest 'scripts remain scoped to their defining instance' => sub {
        my $r1 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        my $r2 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r1->connect };
        run { $r2->connect };

        $r1->define_command(instance_only => {
            keys    => 0,
            lua     => 'return "r1"',
        });

        ok($r1->get_script('instance_only'), 'defining instance has script');
        is($r2->get_script('instance_only'), undef, 'other instance cannot see script');
        ok(!$r1->can('instance_only'), 'script is not visible as a method');
        ok(!$r2->can('instance_only'), 'other instance also has no method');
        is(run { $r1->run_script('instance_only') }, 'r1', 'defining instance can run script explicitly');

        like(
            dies { run { $r2->run_script('instance_only') } },
            qr/Unknown script.*instance_only/,
            'other instance cannot run script without registering it',
        );

        $r1->disconnect;
        $r2->disconnect;
    };

    subtest 'same script name is resolved per instance' => sub {
        my $r1 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        my $r2 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r1->connect };
        run { $r2->connect };

        $r1->define_command(shared_script_name => {
            keys    => 0,
            lua     => 'return "one"',
        });

        $r2->define_command(shared_script_name => {
            keys    => 0,
            lua     => 'return "two"',
        });

        is(run { $r1->run_script('shared_script_name') }, 'one', 'first instance uses first script');
        is(run { $r2->run_script('shared_script_name') }, 'two', 'second instance uses second script');

        $r1->disconnect;
        $r2->disconnect;
    };

    subtest 'scripts do not affect method introspection' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        ok($r->can('get'), 'normal Redis command methods remain visible');
        ok(Async::Redis->can('new'), 'normal class methods remain visible');

        $r->define_command(run_only => {
            keys => 0,
            lua  => 'return "run_only"',
        });

        ok(!$r->can('run_only'), 'registered script is not visible as method');
        ok(!Async::Redis->can('run_only'), 'registered script does not affect class can');
        is(run { $r->run_script('run_only') }, 'run_only', 'registered script still works via run_script');

        $r->disconnect;
    };

    subtest 'run_script error cases' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $r->connect };

        # Unknown script
        like(
            dies { run { $r->run_script('nonexistent') } },
            qr/Unknown script.*nonexistent/,
            'dies on unknown script'
        );

        # Dynamic script without key count
        $r->define_command(needs_keys => {
            keys => 'dynamic',
            lua  => 'return 1',
        });

        like(
            dies { run { $r->run_script('needs_keys') } },
            qr/Key count required/,
            'dies when dynamic script missing key count'
        );

        $r->disconnect;
    };

    subtest 'define_command validation' => sub {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');

        # Missing name
        like(
            dies { $r->define_command(undef, { lua => 'return 1' }) },
            qr/Command name required/,
            'dies on missing name'
        );

        # Missing lua
        like(
            dies { $r->define_command('test', {}) },
            qr/Lua script required/,
            'dies on missing lua'
        );

        # Invalid name
        like(
            dies { $r->define_command('invalid-name', { lua => 'return 1' }) },
            qr/Invalid command name/,
            'dies on invalid name (hyphen)'
        );

        like(
            dies { $r->define_command('123start', { lua => 'return 1' }) },
            qr/Invalid command name/,
            'dies on invalid name (starts with number)'
        );

        # Valid names
        ok($r->define_command('valid_name', { lua => 'return 1' }), 'underscore name ok');
        ok($r->define_command('CamelCase', { lua => 'return 1' }), 'camel case ok');
        ok($r->define_command('name123', { lua => 'return 1' }), 'trailing numbers ok');
    };

    $redis->disconnect;
}

done_testing;
