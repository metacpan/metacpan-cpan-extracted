use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Future::AsyncAwait;
use Future::IO;
use Scalar::Util qw(refaddr);
use Async::Redis;

# :redis auto-skips if Redis unavailable

sub new_redis { Async::Redis->new(host => redis_host(), port => redis_port()) }

subtest 'iterator mode: single channel, 3 messages FIFO' => sub {
    my $sub_c = new_redis;
    my $pub_c = new_redis;
    run { $sub_c->connect };
    run { $pub_c->connect };
    my $ch = 'u-iter-' . $$;
    my $sub = run { $sub_c->subscribe($ch) };

    for my $i (1..3) { run { $pub_c->publish($ch, "m$i") } }

    my @got;
    for my $i (1..3) {
        my $m = run { $sub->next };
        push @got, $m->{data};
    }
    is \@got, ['m1', 'm2', 'm3'], 'FIFO order preserved';
    $sub->_close;
    $sub_c->disconnect;
    $pub_c->disconnect;
};

subtest 'iterator mode: multiple channels' => sub {
    my $sub_c = new_redis;
    my $pub_c = new_redis;
    run { $sub_c->connect };
    run { $pub_c->connect };
    my $cha = 'u-multi-a-' . $$;
    my $chb = 'u-multi-b-' . $$;
    my $sub = run { $sub_c->subscribe($cha, $chb) };
    run { $pub_c->publish($cha, 'va') };
    run { $pub_c->publish($chb, 'vb') };

    my %by_ch;
    for my $i (1..2) {
        my $m = run { $sub->next };
        $by_ch{$m->{channel}} = $m->{data};
    }
    is $by_ch{$cha}, 'va', 'channel a';
    is $by_ch{$chb}, 'vb', 'channel b';
    $sub->_close;
    $sub_c->disconnect;
    $pub_c->disconnect;
};

subtest 'callback mode: fire-and-forget invocations' => sub {
    my $sub_c = new_redis;
    my $pub_c = new_redis;
    run { $sub_c->connect };
    run { $pub_c->connect };
    my $ch = 'u-cb-' . $$;
    my $sub = run { $sub_c->subscribe($ch) };

    my @got;
    my $done = Future->new;
    $sub->on_message(sub {
        my ($self, $msg) = @_;
        push @got, $msg->{data};
        $done->done if @got == 3 && !$done->is_ready;
        return;
    });

    for my $i (1..3) { run { $pub_c->publish($ch, "cb$i") } }
    run { Future->wait_any($done, Future::IO->sleep(2)) };
    is \@got, ['cb1', 'cb2', 'cb3'], 'all 3 callbacks fired in order';
    $sub->_close;
    $sub_c->disconnect;
    $pub_c->disconnect;
};

subtest 'callback mode: Future-returning backpressure serializes invocations' => sub {
    my $sub_c = new_redis;
    my $pub_c = new_redis;
    run { $sub_c->connect };
    run { $pub_c->connect };
    my $ch = 'u-bp-' . $$;
    my $sub = run { $sub_c->subscribe($ch) };

    my @got;
    my @gates;
    $sub->on_message(sub {
        my ($self, $msg) = @_;
        push @got, $msg->{data};
        my $gate = Future->new;
        push @gates, $gate;
        return $gate;
    });

    for my $i (1..3) { run { $pub_c->publish($ch, "bp$i") } }
    # Pump event loop briefly so first message can arrive
    run { Future::IO->sleep(0.1) };
    is scalar(@got), 1, 'only first callback fired while gate pending';

    # Release gate for first, wait for second
    shift(@gates)->done if @gates;
    run { Future::IO->sleep(0.1) };
    shift(@gates)->done if @gates;
    run { Future::IO->sleep(0.1) };

    # All should eventually arrive
    for my $i (1..10) {
        last if @got >= 3;
        run { Future::IO->sleep(0.1) };
    }
    # Release any remaining gates
    $_->done for @gates;
    is scalar(@got), 3, 'all 3 eventually invoked';
    $sub->_close;
    $sub_c->disconnect;
    $pub_c->disconnect;
};

subtest 'pattern subscribe delivers pmessages with pattern field' => sub {
    my $sub_c = new_redis;
    my $pub_c = new_redis;
    run { $sub_c->connect };
    run { $pub_c->connect };
    my $pattern = 'u-pat-*-' . $$;
    my $sub = run { $sub_c->psubscribe($pattern) };
    my $ch = 'u-pat-hello-' . $$;
    run { $pub_c->publish($ch, 'patval') };

    my $m = run { $sub->next };
    is $m->{type}, 'pmessage', 'pmessage type';
    is $m->{channel}, $ch, 'actual channel';
    like $m->{pattern}, qr/u-pat-\*-/, 'pattern carried';
    is $m->{data}, 'patval', 'payload';
    $sub->_close;
    $sub_c->disconnect;
    $pub_c->disconnect;
};

subtest 'subscribe + resubscribe returns fresh sub object' => sub {
    my $r = new_redis;
    run { $r->connect };
    my $ch = 'u-sub1-' . $$;
    my $sub1 = run { $r->subscribe($ch) };

    # _close simulates caller-driven teardown
    $sub1->_close;

    my $sub2 = run { $r->subscribe($ch) };
    isnt refaddr($sub2), refaddr($sub1), 'fresh subscription object';
    $sub2->_close;
    $r->disconnect;
};

subtest 'rapid publish: all messages delivered, no loss' => sub {
    my $sub_c = new_redis;
    my $pub_c = new_redis;
    run { $sub_c->connect };
    run { $pub_c->connect };
    my $ch = 'u-rapid-' . $$;
    my $sub = run { $sub_c->subscribe($ch) };

    my $N = 50;
    for my $i (1..$N) { run { $pub_c->publish($ch, "r$i") } }

    my @got;
    for my $i (1..$N) {
        my $m = run { $sub->next };
        push @got, $m->{data};
    }
    is scalar(@got), $N, "all $N messages delivered";
    is $got[0], 'r1', 'first in order';
    is $got[-1], "r$N", 'last in order';
    $sub->_close;
    $sub_c->disconnect;
    $pub_c->disconnect;
};

subtest 'concurrent subscribers on separate connections each get their messages' => sub {
    my $pub_c = new_redis;
    run { $pub_c->connect };
    my $ch = 'u-concurrent-' . $$;

    my @sub_clients;
    my @subs;
    for my $i (1..3) {
        my $c = new_redis;
        run { $c->connect };
        push @sub_clients, $c;
        push @subs, run { $c->subscribe($ch) };
    }

    run { $pub_c->publish($ch, 'broadcast') };
    for my $sub (@subs) {
        my $m = run { $sub->next };
        is $m->{data}, 'broadcast', 'each subscriber receives';
    }
    for my $sub (@subs) { $sub->_close }
    for my $c (@sub_clients) { $c->disconnect }
    $pub_c->disconnect;
};

subtest '_dispatch_frame: queue bounded by message_queue_depth' => sub {
    # Unit test for _dispatch_frame depth backpressure.
    # Simulates the reader dispatching frames into a subscription whose
    # consumer has not called next() yet.
    use Async::Redis::Subscription;
    my $redis_mock = bless { message_queue_depth => 2 }, 'Async::Redis';
    my $sub = Async::Redis::Subscription->new(redis => $redis_mock);

    # Prime channels so _start_driver guard passes (not needed here, just state)
    $sub->{channels}{'test-ch'} = 1;

    my $frame1 = ['message', 'test-ch', 'v1'];
    my $frame2 = ['message', 'test-ch', 'v2'];
    my $frame3 = ['message', 'test-ch', 'v3'];

    # Dispatch first two — should queue synchronously (depth not exceeded yet)
    my $r1 = $sub->_dispatch_frame($frame1);
    my $r2 = $sub->_dispatch_frame($frame2);
    ok !defined($r1) || !ref($r1), 'first dispatch returns undef (synced)';
    ok !defined($r2) || !ref($r2), 'second dispatch returns undef (synced)';
    is scalar(@{$sub->{_pending_messages}}), 2, '2 messages queued';

    # Third dispatch at depth=2 should return a Future
    my $r3 = $sub->_dispatch_frame($frame3);
    ok ref($r3) && $r3->isa('Future'), 'third dispatch returns Future (queue full)';
    is scalar(@{$sub->{_pending_messages}}), 2, 'queue still at depth (third not yet added)';

    # Consume one message — slot opens, pending dispatch completes
    my $msg1 = shift @{$sub->{_pending_messages}};
    if (my $w = delete $sub->{_slot_waiter}) {
        $w->done unless $w->is_ready;
    }
    # Pump: r3 is a then-chain, so we need to let it resolve
    run { $r3 };
    is scalar(@{$sub->{_pending_messages}}), 2, 'queue back at depth after slot opened';
    is $sub->{_pending_messages}[0]{data}, 'v2', 'v2 now at head';
    is $sub->{_pending_messages}[1]{data}, 'v3', 'v3 appended after slot';
};

done_testing;
