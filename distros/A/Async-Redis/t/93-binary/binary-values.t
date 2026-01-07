# t/93-binary/binary-values.t
use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'binary data with null bytes' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $binary = "hello\x00world\x00binary";
        run { $r->set('bin:null', $binary) };

        my $result = run { $r->get('bin:null') };
        is($result, $binary, 'null bytes preserved');
        is(length($result), length($binary), 'length preserved');

        run { cleanup_keys($r, 'bin:*') };
        $r->disconnect;
    };

    subtest 'binary data with high bytes' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $binary = join('', map { chr($_) } 0..255);
        run { $r->set('bin:high', $binary) };

        my $result = run { $r->get('bin:high') };
        is(length($result), 256, 'all 256 bytes preserved');
        is($result, $binary, 'byte values preserved');

        run { cleanup_keys($r, 'bin:*') };
        $r->disconnect;
    };

    subtest 'binary keys' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $key = "key\x00with\x00nulls";
        run { $r->set($key, 'value') };

        my $result = run { $r->get($key) };
        is($result, 'value', 'binary key works');

        run { $r->del($key) };
        $r->disconnect;
    };

    subtest 'CRLF in values' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        my $value = "line1\r\nline2\r\nline3";
        run { $r->set('bin:crlf', $value) };

        my $result = run { $r->get('bin:crlf') };
        is($result, $value, 'CRLF preserved');

        run { cleanup_keys($r, 'bin:*') };
        $r->disconnect;
    };

    subtest 'large binary values' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # 1MB of random binary data
        my $size = 1024 * 1024;
        my $binary = '';
        for (1..$size) {
            $binary .= chr(int(rand(256)));
        }

        run { $r->set('bin:large', $binary) };

        my $result = run { $r->get('bin:large') };
        is(length($result), $size, 'large binary preserved');

        run { cleanup_keys($r, 'bin:*') };
        $r->disconnect;
    };

    $redis->disconnect;
}

done_testing;
