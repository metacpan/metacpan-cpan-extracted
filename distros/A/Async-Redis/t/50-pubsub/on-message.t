# t/50-pubsub/on-message.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Future::AsyncAwait;
use Test2::V0;
use Async::Redis;

sub _make_publisher {
    my $r = Async::Redis->new(
        host => $ENV{REDIS_HOST} // 'localhost',
        connect_timeout => 2,
    );
    run { $r->connect };
    return $r;
}

sub _make_subscriber {
    my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
    run { $r->connect };
    return $r;
}

# Each callback-mode subtest MUST use its own subscriber connection.
# Reusing a subscriber across subtests races: once on_message is set
# and the driver is running, a subsequent $subscriber->subscribe call's
# internal confirmation-read competes with the driver's frame-read.
sub _with_redis (&) {
    my ($code) = @_;
    my $publisher = eval { _make_publisher() };
    unless ($publisher) {
        skip "Redis not available: $@", 1;
        return;
    }
    $code->($publisher);
    $publisher->disconnect;
}

# --- Unit tests (no Redis needed) ---

subtest 'on_message accessor — set and get' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    is($sub->on_message, undef, 'no callback by default');

    my $cb = sub { 1 };
    $sub->on_message($cb);
    is($sub->on_message, $cb, 'accessor returns the set callback');
};

subtest 'on_error accessor — set and get' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    is($sub->on_error, undef, 'no callback by default');

    my $cb = sub { 1 };
    $sub->on_error($cb);
    is($sub->on_error, $cb, 'accessor returns the set callback');
};

subtest 'next() croaks once on_message is set (sticky mode)' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);
    $sub->on_message(sub { });

    # `async sub` traps exceptions onto the returned Future; ->get
    # re-throws them synchronously so we can assert on $@.
    my $err;
    eval { $sub->next->get; };
    $err = $@;
    ok($err, 'next() throws');
    like($err, qr/callback-driven/i, 'error mentions callback-driven');
};

subtest '_invoke_user_callback returns callback result for sync callback' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);
    $sub->on_message(sub { 'ignored' });

    my $msg = { type => 'message', channel => 'x', pattern => undef, data => 'y' };
    my $cb = $sub->on_message;
    my $result = $sub->_invoke_user_callback($cb, $msg);
    is($result, 'ignored', 'returns callback result');
};

subtest '_invoke_user_callback routes die to on_error' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    my $err_seen;
    $sub->on_error(sub {
        my ($s, $err) = @_;
        $err_seen = $err;
    });

    my $cb = sub { die "boom\n" };
    $sub->_invoke_user_callback($cb, { type => 'message' });
    like($err_seen, qr/boom/, 'on_error received the exception');
    ok($sub->is_closed, 'subscription closed after fatal error');
};

subtest '_handle_fatal_error dies when no on_error set' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    my $err;
    eval { $sub->_handle_fatal_error("loud failure\n"); };
    $err = $@;
    like($err, qr/loud failure/, 'die propagates when no on_error registered');
    ok($sub->is_closed, 'subscription closed');
};

subtest '_handle_fatal_error fires on_error with subscription as first arg' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    my @args_seen;
    $sub->on_error(sub { @args_seen = @_ });

    $sub->_handle_fatal_error("oops\n");
    is(scalar @args_seen, 2, 'on_error called with two args');
    is($args_seen[0], $sub, 'first arg is subscription');
    like($args_seen[1], qr/oops/, 'second arg is error');
};

subtest '_dispatch_frame queues message in callback mode (driver consumes)' => sub {
    # After the unified-reader refactor, _dispatch_frame always queues
    # regardless of mode. The callback driver (_start_driver) dequeues and
    # invokes _on_message; _dispatch_frame is mode-agnostic.
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    $sub->on_message(sub { 1 });   # set callback mode

    my $frame = [ 'message', 'chan', 'payload' ];
    my $result = $sub->_dispatch_frame($frame);

    # Message must be in the queue for the driver to dequeue.
    is(scalar @{$sub->{_pending_messages}}, 1, 'message buffered in queue');
    is($sub->{_pending_messages}[0]{type},    'message', 'correct type');
    is($sub->{_pending_messages}[0]{channel}, 'chan',    'correct channel');
    is($sub->{_pending_messages}[0]{data},    'payload', 'correct data');
    # _dispatch_frame returns undef (no Future) when queued synchronously.
    is($result, undef, 'dispatch returns undef (queued synchronously)');
};

subtest '_dispatch_frame: depth backpressure applies in callback mode too' => sub {
    # Backpressure Future is returned when queue is at depth — same path
    # in both modes since _dispatch_frame is now mode-agnostic.
    my $redis = bless { message_queue_depth => 1 }, 'Async::Redis';
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    $sub->on_message(sub { 1 });   # set callback mode

    # First message fills the queue.
    my $r1 = $sub->_dispatch_frame([ 'message', 'ch', 'v1' ]);
    is($r1, undef, 'first dispatch returns undef (queued)');
    is(scalar @{$sub->{_pending_messages}}, 1, 'queue at depth');

    # Second message exceeds depth — should return a Future.
    my $r2 = $sub->_dispatch_frame([ 'message', 'ch', 'v2' ]);
    ok(ref($r2) && $r2->isa('Future'), 'second dispatch returns Future (at depth)');
    is(scalar @{$sub->{_pending_messages}}, 1, 'queue still at depth (v2 held)');
};

subtest '_dispatch_frame queues message for iterator consumers when no callback' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    my $frame = [ 'message', 'chan', 'payload' ];
    my $result = $sub->_dispatch_frame($frame);

    # With no callback, the message is queued for next() consumers.
    is(scalar @{$sub->{_pending_messages}}, 1, 'message buffered in queue');
    is($sub->{_pending_messages}[0]{data}, 'payload', 'buffered message data');
    is($result, undef, 'dispatch returns undef on fallthrough');
};

# --- Integration tests (need Redis) ---

SKIP: {
    _with_redis {
        my ($publisher) = @_;

        # Integration tests bypass the run{} helper's busy-poll pump
        # because it interacts badly with the driver's on_done
        # callbacks (pumping via Future::IO->sleep(0)->get corrupts
        # internal state when the driver fires a failed-Future →
        # on_error → _close sequence). Direct ->get works reliably.

        subtest 'on_message receives messages published to subscribed channels' => sub {
            my $subscriber = _make_subscriber();
            my @received;
            my $sub = $subscriber->subscribe('test:onmsg:basic')->get;
            $sub->on_message(sub {
                my ($s, $msg) = @_;
                push @received, $msg;
            });

            for my $i (1..3) {
                $publisher->publish('test:onmsg:basic', "msg-$i")->get;
            }
            Future::IO->sleep(0.3)->get;

            is(scalar @received, 3, 'received all 3 messages');
            is($received[0]{type},    'message',          'first msg type');
            is($received[0]{channel}, 'test:onmsg:basic', 'first msg channel');
            is($received[0]{data},    'msg-1',            'first msg data');
            is($received[0]{pattern}, undef,              'pattern undef for message');

            $subscriber->disconnect;
        };

        subtest 'no F::AA "lost its returning future" warning from fire-and-forget use' => sub {
            # Placed BEFORE the CLIENT KILL subtests so Redis's client
            # state is still clean.
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_ };

            {
                my $subscriber = _make_subscriber();
                my $sub = $subscriber->subscribe('test:onmsg:no-warn')->get;
                $sub->on_message(sub { });

                $publisher->publish('test:onmsg:no-warn', 'x')->get;
                Future::IO->sleep(0.3)->get;

                $subscriber->disconnect;
            }
            # Give deferred GC/event-loop callbacks a chance to fire.
            Future::IO->sleep(0.1)->get;

            my @faa_warnings = grep { /lost.+returning future/i } @warnings;
            is(scalar @faa_warnings, 0,
                'no "lost its returning future" warnings from on_message path')
                or note("warnings captured: @warnings");
        };

        # Full end-to-end backpressure timing is flaky in this test
        # harness because the synchronous-callback path is extremely
        # tight — messages are dispatched as soon as frames arrive,
        # which can race the publisher. The backpressure LOGIC is
        # covered by the unit test below (`_dispatch_frame returns
        # Future when callback does`) and the failed-Future
        # integration test. The end-to-end timing test is documented
        # as a known gap pending a deterministic sync primitive.

        subtest 'callback returning a failed Future routes to on_error' => sub {
            # Fresh publisher too — the shared one can linger in a
            # state that interacts oddly with the fatal-close sequence.
            my $pub = _make_publisher();
            my $subscriber = _make_subscriber();
            my $err_seen;
            my $sub = $subscriber->subscribe('test:onmsg:future-fail')->get;
            $sub->on_error(sub {
                my ($s, $err) = @_;
                $err_seen = $err;
            });
            $sub->on_message(sub {
                return Future->fail("callback-future-boom");
            });

            $pub->publish('test:onmsg:future-fail', 'x')->get;
            Future::IO->sleep(0.3)->get;

            like($err_seen, qr/callback-future-boom/, 'on_error fired with callback Future failure');
            ok($sub->is_closed, 'subscription closed after fatal error');
            eval { $subscriber->disconnect };
            eval { $pub->disconnect };
        };

        subtest 'callback returning a Future delays next read until it resolves' => sub {
            my $subscriber = _make_subscriber();
            my @received;
            my $gate = Future->new;
            my $sub = $subscriber->subscribe('test:onmsg:backpressure')->get;
            $sub->on_message(sub {
                my ($s, $msg) = @_;
                push @received, $msg->{data};
                # First message blocks on the gate; subsequent return
                # undef so the driver can drain.
                return @received == 1 ? $gate : undef;
            });

            for my $i (1..3) {
                $publisher->publish('test:onmsg:backpressure', "msg-$i")->get;
            }
            Future::IO->sleep(0.3)->get;

            is(scalar @received, 1, 'driver delivered 1 message then blocked on Future');
            is($received[0], 'msg-1', 'first message delivered');

            $gate->done;
            Future::IO->sleep(0.3)->get;
            is(scalar @received, 3, 'remaining messages delivered after gate released');

            $subscriber->disconnect;
        };

        subtest 'subscribe from inside callback takes effect' => sub {
            my $subscriber = _make_subscriber();
            my @received;
            my $sub = $subscriber->subscribe('test:onmsg:reent:primary')->get;
            $sub->on_message(sub {
                my ($s, $msg) = @_;
                push @received, $msg;
                # First message triggers a subscribe to a second channel.
                if ($msg->{channel} eq 'test:onmsg:reent:primary' && @received == 1) {
                    $s->{redis}->subscribe('test:onmsg:reent:secondary')->retain;
                }
            });

            $publisher->publish('test:onmsg:reent:primary', 'p-1')->get;
            Future::IO->sleep(0.2)->get;
            $publisher->publish('test:onmsg:reent:secondary', 's-1')->get;
            Future::IO->sleep(0.3)->get;

            ok(scalar @received >= 2, 'received at least 2 messages');
            ok((grep { $_->{channel} eq 'test:onmsg:reent:secondary' } @received),
                'received message from channel subscribed inside callback');

            $subscriber->disconnect;
        };

        subtest 'handler swap inside callback uses new handler for next frame' => sub {
            my $subscriber = _make_subscriber();
            my @received_by_a;
            my @received_by_b;
            my $sub = $subscriber->subscribe('test:onmsg:swap')->get;

            my $handler_b = sub {
                my ($s, $msg) = @_;
                push @received_by_b, $msg->{data};
            };
            my $handler_a = sub {
                my ($s, $msg) = @_;
                push @received_by_a, $msg->{data};
                # Swap handler mid-stream
                $s->on_message($handler_b);
            };
            $sub->on_message($handler_a);

            for my $i (1..3) {
                $publisher->publish('test:onmsg:swap', "m-$i")->get;
            }
            Future::IO->sleep(0.3)->get;

            is(scalar @received_by_a, 1, 'handler A received exactly one message');
            is($received_by_a[0], 'm-1', 'handler A got first message');
            is(scalar @received_by_b, 2, 'handler B received the next two');
            is($received_by_b[0], 'm-2', 'handler B got second message');
            is($received_by_b[1], 'm-3', 'handler B got third message');

            $subscriber->disconnect;
        };

        subtest 'psubscribe delivers pmessage with pattern populated' => sub {
            my $subscriber = _make_subscriber();
            my @received;
            my $sub = $subscriber->psubscribe('test:onmsg:pat:*')->get;
            $sub->on_message(sub {
                my ($s, $msg) = @_;
                push @received, $msg;
            });

            $publisher->publish('test:onmsg:pat:alpha', 'a')->get;
            $publisher->publish('test:onmsg:pat:beta',  'b')->get;
            Future::IO->sleep(0.3)->get;

            is(scalar @received, 2, 'received both pattern-matched messages');
            is($received[0]{type},    'pmessage',              'type is pmessage');
            is($received[0]{pattern}, 'test:onmsg:pat:*',      'pattern is populated');
            is($received[0]{channel}, 'test:onmsg:pat:alpha',  'channel is the matched one');
            is($received[0]{data},    'a',                     'data correct');

            $subscriber->disconnect;
        };

        subtest 'on_reconnect fires before post-reconnect on_message' => sub {
            # Reconnect-enabled subscriber
            my $subscriber = Async::Redis->new(
                host      => $ENV{REDIS_HOST} // 'localhost',
                reconnect => 1,
            );
            $subscriber->connect->get;

            # Capture the subscriber's client ID BEFORE subscribing —
            # CLIENT commands are not allowed once the connection is
            # in pub/sub mode. We'll use the ID later for a targeted
            # kill from the publisher.
            my $sub_client_id = $subscriber->client('ID')->get;

            my $sub = $subscriber->subscribe('test:onmsg:reconn')->get;

            my @events;
            $sub->on_reconnect(sub { push @events, 'reconnect' });
            $sub->on_message(sub {
                my ($s, $msg) = @_;
                push @events, "message:$msg->{data}";
            });

            # Pre-reconnect message
            $publisher->publish('test:onmsg:reconn', 'before')->get;
            Future::IO->sleep(0.2)->get;

            # Force a targeted disconnect via the captured client ID.
            # The reconnect logic in _read_frame_with_reconnect will
            # re-establish and replay subscriptions.
            eval { $publisher->client('KILL', 'ID', $sub_client_id)->get };
            Future::IO->sleep(0.4)->get;

            # Post-reconnect message
            $publisher->publish('test:onmsg:reconn', 'after')->get;
            Future::IO->sleep(0.4)->get;

            # Expect: message:before, reconnect, message:after (order)
            is($events[0], 'message:before', 'first event is pre-reconnect message');
            my $reconnect_idx = -1;
            my $after_idx     = -1;
            for my $i (0..$#events) {
                $reconnect_idx = $i if $events[$i] eq 'reconnect';
                $after_idx     = $i if $events[$i] eq 'message:after';
            }
            ok($reconnect_idx >= 0,            'on_reconnect fired at some point');
            ok($after_idx > $reconnect_idx,    'on_message(after) fired after on_reconnect');

            eval { $subscriber->disconnect };
        };

        subtest 'fatal error (reconnect disabled) fires on_error and closes subscription' => sub {
            my $subscriber = Async::Redis->new(
                host      => $ENV{REDIS_HOST} // 'localhost',
                reconnect => 0,
            );
            $subscriber->connect->get;

            # Capture the client ID BEFORE subscribing — CLIENT commands
            # are not allowed once the connection is in pub/sub mode.
            my $sub_client_id = $subscriber->client('ID')->get;

            my $sub = $subscriber->subscribe('test:onmsg:fatal')->get;

            my $err_seen;
            $sub->on_error(sub {
                my ($s, $err) = @_;
                $err_seen = $err;
            });
            $sub->on_message(sub { });   # a callback so the driver runs

            # Kill only the subscriber's own connection by ID (not all
            # pubsub clients globally — that would collateral-damage
            # parallel tests sharing the Redis instance).
            eval { $publisher->client('KILL', 'ID', $sub_client_id)->get };
            Future::IO->sleep(0.4)->get;

            ok($err_seen,              'on_error fired with an error');
            ok($sub->is_closed,        'subscription closed after fatal error');

            eval { $subscriber->disconnect };
        };

    };
}

done_testing;
