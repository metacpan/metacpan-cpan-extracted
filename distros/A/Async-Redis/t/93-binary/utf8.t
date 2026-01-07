# t/93-binary/utf8.t
use strict;
use warnings;
use utf8;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'UTF-8 values' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $utf8 = "Hello 世界 🌍 مرحبا";
        run { $r->set('utf8:value', $utf8) };

        my $result = run { $r->get('utf8:value') };
        ok(defined $result, 'got result');

        # Redis stores bytes, so we compare byte-level
        my $expected = $utf8;
        utf8::encode($expected) if utf8::is_utf8($expected);

        is($result, $expected, 'UTF-8 bytes preserved');

        run { cleanup_keys($r, 'utf8:*') };
        $r->disconnect;
    };

    subtest 'UTF-8 in hash fields' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $field = "フィールド";
        my $value = "値";

        run { $r->hset('utf8:hash', $field, $value) };

        my $result = run { $r->hget('utf8:hash', $field) };
        ok(defined $result, 'got hash field');

        my $expected = $value;
        utf8::encode($expected) if utf8::is_utf8($expected);
        is($result, $expected, 'UTF-8 hash value preserved');

        run { cleanup_keys($r, 'utf8:*') };
        $r->disconnect;
    };

    subtest 'UTF-8 in list elements' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my @items = ("项目1", "项目2", "项目3");
        for my $item (@items) {
            run { $r->rpush('utf8:list', $item) };
        }

        my $result = run { $r->lrange('utf8:list', 0, -1) };
        is(scalar @$result, 3, 'got 3 items');

        run { cleanup_keys($r, 'utf8:*') };
        $r->disconnect;
    };

    subtest 'emoji values' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $emoji = "🚀🎉💻🔥";
        run { $r->set('utf8:emoji', $emoji) };

        my $result = run { $r->get('utf8:emoji') };
        ok(defined $result, 'got emoji value');

        my $expected = $emoji;
        utf8::encode($expected) if utf8::is_utf8($expected);
        is($result, $expected, 'emoji bytes preserved');

        run { cleanup_keys($r, 'utf8:*') };
        $r->disconnect;
    };

    $redis->disconnect;
}

done_testing;
