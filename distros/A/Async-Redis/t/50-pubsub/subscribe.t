# t/50-pubsub/subscribe.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Future::AsyncAwait;
use Test2::V0;
use Async::Redis;
use Future;

SKIP: {
    my $publisher = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $publisher;

    subtest 'basic subscribe and receive' => sub {
        my $subscriber = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $subscriber->connect };

        # Subscribe first
        my $sub = run { $subscriber->subscribe('test:sub:basic') };
        ok($sub->isa('Async::Redis::Subscription'), 'returns Subscription object');
        is([sort $sub->channels], ['test:sub:basic'], 'tracks subscribed channels');

        # Publish messages in background
        my $publish_future = (async sub {
            await Future::IO->sleep(0.1);
            for my $i (1..3) {
                my $listeners = await $publisher->publish('test:sub:basic', "message $i");
                ok($listeners >= 1, "publish $i reached subscriber");
            }
        })->();

        # Receive messages
        my @received;
        for my $i (1..3) {
            my $msg = run { $sub->next };
            push @received, $msg;
        }

        await_f($publish_future);

        is(scalar @received, 3, 'received 3 messages');
        is($received[0]{type}, 'message', 'message type');
        is($received[0]{channel}, 'test:sub:basic', 'correct channel');
        is($received[0]{data}, 'message 1', 'correct data');

        $subscriber->disconnect;
    };

    subtest 'in_pubsub blocks regular commands' => sub {
        my $subscriber = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $subscriber->connect };

        # Start subscription
        my $sub = run { $subscriber->subscribe('test:sub:block') };
        ok($subscriber->in_pubsub, 'connection marked as in_pubsub');

        # Regular commands should fail on pubsub connection
        my $error;
        eval {
            run { $subscriber->get('some:key') };
        };
        $error = $@;
        ok($error, 'regular command fails on pubsub connection');
        like("$error", qr/pubsub|PubSub/i, 'error mentions pubsub mode');

        $subscriber->disconnect;
    };

    $publisher->disconnect;
}

done_testing;
