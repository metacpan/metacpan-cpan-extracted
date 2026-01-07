#!/usr/bin/env perl

use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Future::AsyncAwait;
use Test2::V0;
use Time::HiRes qw(time);

use lib 'lib';
use Async::Redis;

# Skip if no Redis available

# Load Future::IO implementation
eval { require Future::IO::Impl::IOAsync };

# ============================================================================
# Test: Pub/Sub basic flow
# ============================================================================

subtest 'publish and subscribe' => sub {
    # Publisher connection
    my $pub = Async::Redis->new(host => redis_host(), port => redis_port());
    get_loop()->await($pub->connect);

    # Subscriber connection
    my $sub = Async::Redis->new(host => redis_host(), port => redis_port());
    get_loop()->await($sub->connect);

    my @received;
    my $done = get_loop()->new_future;

    # Start subscriber in background
    my $sub_future = (async sub {
        my $subscription = await $sub->subscribe('test:channel');

        # Read 3 messages then stop
        for my $i (1..3) {
            my $msg = await $subscription->next_message;
            push @received, $msg;
        }

        $done->done;
    })->();

    # Give subscriber time to subscribe
    get_loop()->await(Future::IO->sleep(0.1));

    # Publish messages
    my $listeners;
    $listeners = get_loop()->await($pub->publish('test:channel', 'message 1'));
    ok $listeners >= 1, "publish returned $listeners listeners";

    get_loop()->await($pub->publish('test:channel', 'message 2'));
    get_loop()->await($pub->publish('test:channel', 'message 3'));

    # Wait for subscriber to receive all
    get_loop()->await($done);

    is scalar(@received), 3, 'received 3 messages';
    is $received[0]{channel}, 'test:channel', 'correct channel';
    is $received[0]{message}, 'message 1', 'correct message 1';
    is $received[1]{message}, 'message 2', 'correct message 2';
    is $received[2]{message}, 'message 3', 'correct message 3';

    $pub->disconnect;
    $sub->disconnect;
};

# ============================================================================
# Test: Multiple channels
# ============================================================================

subtest 'multiple channel subscription' => sub {
    my $pub = Async::Redis->new(host => redis_host(), port => redis_port());
    my $sub = Async::Redis->new(host => redis_host(), port => redis_port());

    get_loop()->await(Future->needs_all($pub->connect, $sub->connect));

    my @received;
    my $done = get_loop()->new_future;

    # Subscribe to multiple channels
    my $sub_future = (async sub {
        my $subscription = await $sub->subscribe('chan:a', 'chan:b', 'chan:c');

        for my $i (1..3) {
            my $msg = await $subscription->next_message;
            push @received, $msg;
        }
        $done->done;
    })->();

    get_loop()->await(Future::IO->sleep(0.1));

    # Publish to different channels
    get_loop()->await($pub->publish('chan:a', 'msg-a'));
    get_loop()->await($pub->publish('chan:b', 'msg-b'));
    get_loop()->await($pub->publish('chan:c', 'msg-c'));

    get_loop()->await($done);

    is scalar(@received), 3, 'received from all channels';

    my %by_channel = map { $_->{channel} => $_->{message} } @received;
    is $by_channel{'chan:a'}, 'msg-a', 'got message from chan:a';
    is $by_channel{'chan:b'}, 'msg-b', 'got message from chan:b';
    is $by_channel{'chan:c'}, 'msg-c', 'got message from chan:c';

    $pub->disconnect;
    $sub->disconnect;
};

# ============================================================================
# Test: Pub/Sub doesn't block other connections
# ============================================================================

subtest 'pubsub nonblocking' => sub {
    my $pub = Async::Redis->new(host => redis_host(), port => redis_port());
    my $sub = Async::Redis->new(host => redis_host(), port => redis_port());
    my $worker = Async::Redis->new(host => redis_host(), port => redis_port());

    get_loop()->await(Future->needs_all($pub->connect, $sub->connect, $worker->connect));

    my @pubsub_msgs;
    my @worker_results;
    my $msg_count = 0;

    # Subscriber waiting for messages
    my $sub_future = (async sub {
        my $subscription = await $sub->subscribe('work:results');

        while ($msg_count < 5) {
            my $msg = await $subscription->next_message;
            push @pubsub_msgs, $msg;
            $msg_count++;
        }
    })->();

    get_loop()->await(Future::IO->sleep(0.1));

    # Worker doing regular Redis operations AND publishing results
    my $worker_future = (async sub {
        for my $i (1..5) {
            # Do some work
            await $worker->set("work:item:$i", "processing");
            await $worker->incr("work:counter");

            # Publish result
            await $pub->publish('work:results', "completed:$i");

            push @worker_results, $i;
        }
    })->();

    # Wait for both
    get_loop()->await(Future->needs_all($sub_future, $worker_future));

    is scalar(@pubsub_msgs), 5, 'received 5 pubsub messages';
    is scalar(@worker_results), 5, 'worker completed 5 items';

    # Cleanup
    get_loop()->await($worker->del(map { "work:item:$_" } 1..5));
    get_loop()->await($worker->del('work:counter'));

    $pub->disconnect;
    $sub->disconnect;
    $worker->disconnect;
};

done_testing;
