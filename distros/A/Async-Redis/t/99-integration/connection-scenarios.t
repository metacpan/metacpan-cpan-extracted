#!/usr/bin/env perl
# Test: Various connection scenarios
use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'reconnect after disconnect' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Verify connection works
        my $pong = run { $r->ping };
        is($pong, 'PONG', 'initial ping works');

        # Disconnect and reconnect
        $r->disconnect;
        run { $r->connect };

        $pong = run { $r->ping };
        is($pong, 'PONG', 'ping after reconnect works');

        $r->disconnect;
    };

    subtest 'multiple sequential connections' => sub {
        for my $i (1..5) {
            my $r = Async::Redis->new(
                host => $ENV{REDIS_HOST} // 'localhost',
            );
            run { $r->connect };

            my $result = run { $r->set("conntest:$i", "value$i") };
            is($result, 'OK', "connection $i SET works");

            my $val = run { $r->get("conntest:$i") };
            is($val, "value$i", "connection $i GET works");

            run { cleanup_keys($r, "conntest:$i") };
            $r->disconnect;
        }
        pass('completed 5 sequential connections');
    };

    subtest 'connection with timeout' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 5,
            read_timeout => 5,
        );
        run { $r->connect };

        my $pong = run { $r->ping };
        is($pong, 'PONG', 'connection with timeouts works');

        $r->disconnect;
    };

    subtest 'database selection' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            database => 1,
        );
        run { $r->connect };

        # Set a key in database 1
        run { $r->set('dbtest:key', 'in_db1') };

        # Connect to database 0 and verify key doesn't exist
        my $r0 = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            database => 0,
        );
        run { $r0->connect };

        my $val0 = run { $r0->get('dbtest:key') };
        ok(!defined $val0, 'key not in database 0');

        # Verify key exists in database 1
        my $val1 = run { $r->get('dbtest:key') };
        is($val1, 'in_db1', 'key exists in database 1');

        run { cleanup_keys($r, 'dbtest:*') };
        $r->disconnect;
        $r0->disconnect;
    };

    subtest 'rapid connect/disconnect cycles' => sub {
        for my $i (1..10) {
            my $r = Async::Redis->new(
                host => $ENV{REDIS_HOST} // 'localhost',
            );
            run { $r->connect };
            run { $r->ping };
            $r->disconnect;
        }
        pass('completed 10 rapid connect/disconnect cycles');
    };

    $redis->disconnect;
}

done_testing;
