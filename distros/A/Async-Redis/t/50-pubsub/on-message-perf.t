# t/50-pubsub/on-message-perf.t
# Informational perf baseline — not a pass/fail gate.
# Compares throughput of await $sub->next vs on_message callback.

use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Future::AsyncAwait;
use Test2::V0;
use Async::Redis;
use Time::HiRes ();

my $MSG_COUNT = $ENV{ONMESSAGE_PERF_COUNT} // 10_000;

SKIP: {
    my $publisher = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        $r->connect->get;
        $r;
    };
    skip "Redis not available: $@", 1 unless $publisher;

    # --- iterator baseline ---
    subtest "await next() throughput over $MSG_COUNT messages" => sub {
        my $subscriber = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        $subscriber->connect->get;
        my $sub = $subscriber->subscribe('perf:next')->get;

        my $received = 0;
        my $t0 = Time::HiRes::time();

        my $recv_f = (async sub {
            for my $n (1 .. $MSG_COUNT) {
                my $msg = await $sub->next;
                $received++;
            }
        })->();

        # Publish in the background
        my $pub_f = (async sub {
            await Future::IO->sleep(0.05);
            for my $i (1 .. $MSG_COUNT) {
                await $publisher->publish('perf:next', "m-$i");
            }
        })->();

        Future->wait_all($recv_f, $pub_f)->get;

        my $elapsed = Time::HiRes::time() - $t0;
        is($received, $MSG_COUNT, "received all $MSG_COUNT messages via next()");
        note(sprintf("await next(): %.3fs for %d msgs = %.0f msg/s",
            $elapsed, $MSG_COUNT, $MSG_COUNT / $elapsed));

        $subscriber->disconnect;
    };

    # --- callback baseline ---
    subtest "on_message throughput over $MSG_COUNT messages" => sub {
        my $subscriber = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        $subscriber->connect->get;
        my $sub = $subscriber->subscribe('perf:cb')->get;

        my $received = 0;
        my $done_f = Future->new;
        $sub->on_message(sub {
            $received++;
            $done_f->done if $received == $MSG_COUNT;
        });

        my $t0 = Time::HiRes::time();

        my $pub_f = (async sub {
            await Future::IO->sleep(0.05);
            for my $i (1 .. $MSG_COUNT) {
                await $publisher->publish('perf:cb', "m-$i");
            }
        })->();

        Future->wait_all($pub_f, $done_f)->get;

        my $elapsed = Time::HiRes::time() - $t0;
        is($received, $MSG_COUNT, "received all $MSG_COUNT messages via on_message");
        note(sprintf("on_message: %.3fs for %d msgs = %.0f msg/s",
            $elapsed, $MSG_COUNT, $MSG_COUNT / $elapsed));

        $subscriber->disconnect;
    };

    $publisher->disconnect;
}

done_testing;
