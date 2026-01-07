# t/60-scripting/auto-fallback.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Digest::SHA qw(sha1_hex);

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    my $script = 'return KEYS[1] .. ":" .. ARGV[1]';
    my $sha = lc(sha1_hex($script));

    subtest 'evalsha_or_eval with unknown SHA falls back' => sub {
        # Flush scripts to ensure SHA unknown
        run { $redis->script_flush };

        # This should try EVALSHA, get NOSCRIPT, then use EVAL
        my $result = run { $redis->evalsha_or_eval(
            $sha,
            $script,
            1,
            'mykey',
            'myarg',
        ) };

        is($result, 'mykey:myarg', 'fallback to EVAL worked');
    };

    subtest 'evalsha_or_eval with known SHA uses SHA' => sub {
        # Load the script
        run { $redis->script_load($script) };

        my $result = run { $redis->evalsha_or_eval(
            $sha,
            $script,
            1,
            'key2',
            'arg2',
        ) };

        is($result, 'key2:arg2', 'EVALSHA worked');
    };

    subtest 'evalsha_or_eval caches SHA after fallback' => sub {
        run { $redis->script_flush };

        my $new_script = 'return "cached"';
        my $new_sha = lc(sha1_hex($new_script));

        # First call: fallback to EVAL
        my $r1 = run { $redis->evalsha_or_eval($new_sha, $new_script, 0) };
        is($r1, 'cached', 'first call worked');

        # Script should now be loaded on server
        my $exists = run { $redis->script_exists($new_sha) };
        is($exists->[0], 1, 'script now cached on server');

        # Second call should use EVALSHA directly
        my $r2 = run { $redis->evalsha_or_eval($new_sha, $new_script, 0) };
        is($r2, 'cached', 'second call worked');
    };
}

done_testing;
