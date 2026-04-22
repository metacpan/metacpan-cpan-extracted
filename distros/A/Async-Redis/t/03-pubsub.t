#!/usr/bin/env perl

use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Future::AsyncAwait;
use Test2::V0;
use Time::HiRes qw(time);
use Future::IO;

use lib 'lib';
use Async::Redis;

# Each subtest body runs inside a single async sub and ->get is called
# exactly once at the end. This avoids the Future::AsyncAwait
# "lost its returning future" pitfall that arose when the body mixed
# fire-and-forget `(async sub { ... })->()` with synchronous `->get`
# on a separate signal Future (the caller would unwind through the
# subtest's closing brace before F::AA finished bookkeeping on the
# background sub, destroying its returning Future mid-suspension).

# ============================================================================
# Test: Pub/Sub basic flow
# ============================================================================

subtest 'publish and subscribe' => sub {
    (async sub {
        my $pub = Async::Redis->new(host => redis_host(), port => redis_port());
        my $sub = Async::Redis->new(host => redis_host(), port => redis_port());
        await Future->needs_all($pub->connect, $sub->connect);

        my $subscription = await $sub->subscribe('test:channel');

        # Publish in the background while we read.
        my $pub_f = (async sub {
            await Future::IO->sleep(0.05);
            my $listeners = await $pub->publish('test:channel', 'message 1');
            ok $listeners >= 1, "publish returned $listeners listeners";
            await $pub->publish('test:channel', 'message 2');
            await $pub->publish('test:channel', 'message 3');
        })->();

        my @received;
        for my $i (1..3) {
            push @received, await $subscription->next_message;
        }
        await $pub_f;

        is scalar(@received), 3, 'received 3 messages';
        is $received[0]{channel}, 'test:channel', 'correct channel';
        is $received[0]{message}, 'message 1', 'correct message 1';
        is $received[1]{message}, 'message 2', 'correct message 2';
        is $received[2]{message}, 'message 3', 'correct message 3';

        $pub->disconnect;
        $sub->disconnect;
    })->()->get;
};

# ============================================================================
# Test: Multiple channels
# ============================================================================

subtest 'multiple channel subscription' => sub {
    (async sub {
        my $pub = Async::Redis->new(host => redis_host(), port => redis_port());
        my $sub = Async::Redis->new(host => redis_host(), port => redis_port());
        await Future->needs_all($pub->connect, $sub->connect);

        my $subscription = await $sub->subscribe('chan:a', 'chan:b', 'chan:c');

        my $pub_f = (async sub {
            await Future::IO->sleep(0.05);
            await $pub->publish('chan:a', 'msg-a');
            await $pub->publish('chan:b', 'msg-b');
            await $pub->publish('chan:c', 'msg-c');
        })->();

        my @received;
        for my $i (1..3) {
            push @received, await $subscription->next_message;
        }
        await $pub_f;

        is scalar(@received), 3, 'received from all channels';

        my %by_channel = map { $_->{channel} => $_->{message} } @received;
        is $by_channel{'chan:a'}, 'msg-a', 'got message from chan:a';
        is $by_channel{'chan:b'}, 'msg-b', 'got message from chan:b';
        is $by_channel{'chan:c'}, 'msg-c', 'got message from chan:c';

        $pub->disconnect;
        $sub->disconnect;
    })->()->get;
};

# ============================================================================
# Test: Pub/Sub doesn't block other connections
# ============================================================================

subtest 'pubsub nonblocking' => sub {
    (async sub {
        my $pub    = Async::Redis->new(host => redis_host(), port => redis_port());
        my $sub    = Async::Redis->new(host => redis_host(), port => redis_port());
        my $worker = Async::Redis->new(host => redis_host(), port => redis_port());
        await Future->needs_all($pub->connect, $sub->connect, $worker->connect);

        my $subscription = await $sub->subscribe('work:results');

        # Worker runs in parallel: regular commands + publishes.
        my @worker_results;
        my $worker_f = (async sub {
            for my $i (1..5) {
                await $worker->set("work:item:$i", "processing");
                await $worker->incr("work:counter");
                await $pub->publish('work:results', "completed:$i");
                push @worker_results, $i;
            }
        })->();

        my @pubsub_msgs;
        for my $n (1..5) {
            push @pubsub_msgs, await $subscription->next_message;
        }
        await $worker_f;

        is scalar(@pubsub_msgs),    5, 'received 5 pubsub messages';
        is scalar(@worker_results), 5, 'worker completed 5 items';

        # Cleanup
        await $worker->del(map { "work:item:$_" } 1..5);
        await $worker->del('work:counter');

        $pub->disconnect;
        $sub->disconnect;
        $worker->disconnect;
    })->()->get;
};

done_testing;
