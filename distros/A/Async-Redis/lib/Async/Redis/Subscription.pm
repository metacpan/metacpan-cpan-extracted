package Async::Redis::Subscription;

use strict;
use warnings;
use 5.018;

use Carp ();
use Future;
use Future::AsyncAwait;
use Future::IO;
use Scalar::Util ();

our $VERSION = '0.001';

# Synchronous recursion depth for the callback driver loop. See
# _start_driver. Package-level so local() can scope it dynamically —
# local() cannot be applied to lexicals.
our $SYNC_DEPTH = 0;
use constant MAX_SYNC_DEPTH => 32;

sub new {
    my ($class, %args) = @_;

    return bless {
        redis            => $args{redis},
        channels         => {},      # channel => 1 (for regular subscribe)
        patterns         => {},      # pattern => 1 (for psubscribe)
        sharded_channels => {},      # channel => 1 (for ssubscribe)
        _message_queue   => [],      # Buffer for messages
        _waiters         => [],      # Futures waiting for messages
        _on_reconnect    => undef,   # Callback for reconnect notification
        _on_message      => undef,   # Message-arrived callback (Task 3)
        _on_error        => undef,   # Fatal-error callback (Task 3)
        _driver_step     => undef,   # Running driver loop closure (callback mode)
        _current_read    => undef,   # Strong ref to in-flight read Future (F::AA GC pin)
        _closed          => 0,
    }, $class;
}

# Set/get reconnect callback
sub on_reconnect {
    my ($self, $cb) = @_;
    $self->{_on_reconnect} = $cb if @_ > 1;
    return $self->{_on_reconnect};
}

# Set/get message-arrived callback. Once set, next() croaks — the
# subscription is in callback mode for the rest of its lifetime.
# $cb->($sub, $msg) receives the Subscription and the message hashref.
sub on_message {
    my ($self, $cb) = @_;
    if (@_ > 1) {
        if (!$cb && $self->{_on_message}) {
            Carp::croak(
                "on_message is sticky; cannot clear once set "
              . "(construct a new Subscription for iterator mode)"
            );
        }
        $self->{_on_message} = $cb;
        # If the subscription already has channels and is open, start
        # the driver. If not, it'll be started when channels are added.
        $self->_start_driver if $cb;
    }
    return $self->{_on_message};
}

# Set/get fatal-error callback. Fires once per fatal error; default
# (when unset) is to die so silent death is impossible.
# $cb->($sub, $err) receives the Subscription and the error.
sub on_error {
    my ($self, $cb) = @_;
    if (@_ > 1) {
        $self->{_on_error} = $cb;
    }
    return $self->{_on_error};
}

# Invoke a user-supplied callback with the standard exception-handling
# policy: save/restore $@, use eval-and-check-boolean idiom to survive
# DESTROY side effects, and route die to the fatal-error handler.
# Returns the callback's return value. Task 7 wires backpressure: if
# the return is a Future the driver will await it before the next
# read. Task 6's driver does not yet consume the return value.
sub _invoke_user_callback {
    my ($self, $cb, $msg) = @_;
    local $@;
    my $result;
    my $ok = eval {
        $result = $cb->($self, $msg);
        1;
    };
    unless ($ok) {
        my $err = $@ // 'unknown error';
        $self->_handle_fatal_error("on_message callback died: $err");
        return undef;
    }
    return $result;
}

# Single chokepoint for fatal errors from either the read loop or the
# callback path. Closes the subscription, fires on_error if registered,
# and dies loudly if not. Loud-by-default prevents silent zombies.
sub _handle_fatal_error {
    my ($self, $err) = @_;
    $self->_close;
    if (my $cb = $self->{_on_error}) {
        local $@;
        my $ok = eval { $cb->($self, $err); 1 };
        unless ($ok) {
            Carp::carp("on_error callback died: " . ($@ // 'unknown error'));
        }
        return;
    }
    die $err;
}

# Track a channel subscription
sub _add_channel {
    my ($self, $channel) = @_;
    $self->{channels}{$channel} = 1;
    $self->_start_driver;
}

sub _add_pattern {
    my ($self, $pattern) = @_;
    $self->{patterns}{$pattern} = 1;
    $self->_start_driver;
}

sub _add_sharded_channel {
    my ($self, $channel) = @_;
    $self->{sharded_channels}{$channel} = 1;
    $self->_start_driver;
}

sub _remove_channel {
    my ($self, $channel) = @_;
    delete $self->{channels}{$channel};
}

sub _remove_pattern {
    my ($self, $pattern) = @_;
    delete $self->{patterns}{$pattern};
}

sub _remove_sharded_channel {
    my ($self, $channel) = @_;
    delete $self->{sharded_channels}{$channel};
}

# List subscribed channels/patterns
sub channels { keys %{shift->{channels}} }
sub patterns { keys %{shift->{patterns}} }
sub sharded_channels { keys %{shift->{sharded_channels}} }

sub channel_count {
    my ($self) = @_;
    return scalar(keys %{$self->{channels}})
         + scalar(keys %{$self->{patterns}})
         + scalar(keys %{$self->{sharded_channels}});
}

# Receive next message (async iterator pattern)
async sub next {
    my ($self) = @_;

    return undef if $self->{_closed};

    # Exclusivity check: callback mode disables iterator mode.
    # (The _on_message slot is initialized in new(); inert until Task 3.)
    if ($self->{_on_message}) {
        Carp::croak("Cannot call next() on a callback-driven subscription");
    }

    if (@{$self->{_message_queue}}) {
        return shift @{$self->{_message_queue}};
    }

    while (1) {
        my $frame = await $self->_read_frame_with_reconnect;
        last unless $frame;
        $self->_dispatch_frame($frame);
        # _dispatch_frame buffers the message into _message_queue (when
        # on_message is unset — which it must be in this branch since
        # the exclusivity check above throws otherwise). Pull from queue.
        if (@{$self->{_message_queue}}) {
            return shift @{$self->{_message_queue}};
        }
        # Otherwise it was a non-message frame; loop for another.
    }

    return undef;
}

# Read one pub/sub frame from the underlying connection. On transient
# read error, attempt reconnect if enabled and fire on_reconnect on
# success; on unrecoverable failure, propagate the error.
# Returns a Future resolving to the raw frame (arrayref) or undef if
# the connection is gone and no more frames are available.
# Shared by next() and the callback driver loop added in a later task.
async sub _read_frame_with_reconnect {
    my ($self) = @_;
    my $redis = $self->{redis};

    while (1) {
        my $frame;
        my $ok = eval {
            $frame = await $redis->_read_pubsub_frame;
            1;
        };

        unless ($ok) {
            my $error = $@;
            if ($redis->{reconnect} && $self->channel_count > 0) {
                my $reconnect_ok = eval {
                    await $redis->_reconnect_pubsub;
                    1;
                };
                unless ($reconnect_ok) {
                    die $error;
                }

                if ($self->{_on_reconnect}) {
                    $self->{_on_reconnect}->($self);
                }

                next;
            }
            die $error;
        }

        return $frame;
    }
}

# Convert a raw RESP pub/sub frame into a message hashref and deliver it.
# When on_message is set (callback mode), invoke the callback via
# _invoke_user_callback and return its result (which may be a Future
# for consumer-side backpressure). Otherwise buffer the message via
# _deliver_message for next()/iterator consumers and return undef.
#
# Non-message frames (subscribe confirmations, etc.) return undef and
# take no action — the caller's loop will read another frame.
sub _dispatch_frame {
    my ($self, $frame) = @_;
    return unless $frame && ref $frame eq 'ARRAY';

    my $type = $frame->[0] // '';
    my $msg;

    if ($type eq 'message') {
        $msg = {
            type    => 'message',
            channel => $frame->[1],
            pattern => undef,
            data    => $frame->[2],
        };
    }
    elsif ($type eq 'pmessage') {
        $msg = {
            type    => 'pmessage',
            pattern => $frame->[1],
            channel => $frame->[2],
            data    => $frame->[3],
        };
    }
    elsif ($type eq 'smessage') {
        $msg = {
            type    => 'smessage',
            channel => $frame->[1],
            pattern => undef,
            data    => $frame->[2],
        };
    }
    else {
        return undef;   # non-message frame
    }

    if (my $cb = $self->{_on_message}) {
        return $self->_invoke_user_callback($cb, $msg);
    }

    $self->_deliver_message($msg);
    return undef;
}

# Start the callback driver loop if not already running. Idempotent.
# Runs while: on_message is set AND channel_count > 0 AND !_closed.
# Uses weak refs on $self and $step to break cycles so DESTROY fires
# promptly when external refs drop. Uses local($SYNC_DEPTH) to bound
# synchronous recursion depth when on_done fires synchronously (as
# it does when the underlying read buffer has multiple frames ready);
# past MAX_SYNC_DEPTH iterations, yields to the loop via Future::IO->later.
sub _start_driver {
    my ($self) = @_;
    return if $self->{_driver_step};
    return unless $self->{_on_message};
    return if $self->{_closed};
    return unless $self->channel_count > 0;

    Scalar::Util::weaken(my $weak = $self);

    my $step;
    my $weak_step;
    $step = sub {
        return unless $weak && !$weak->{_closed};

        # Trampoline: once 32 synchronous iterations deep, yield to the
        # loop. Prevents stack overflow when a single TCP recv delivers
        # many buffered frames whose Futures are already ready.
        if ($SYNC_DEPTH >= MAX_SYNC_DEPTH) {
            Future::IO->later(sub {
                $weak_step->() if $weak_step && $weak && !$weak->{_closed};
            });
            return;
        }
        local $SYNC_DEPTH = $SYNC_DEPTH + 1;

        # Keep a strong ref to the in-flight read Future on the
        # subscription so the async sub behind _read_frame_with_reconnect
        # isn't GC'd mid-suspension (F::AA's "lost returning future").
        my $f = $weak->{_current_read} = $weak->_read_frame_with_reconnect;

        $f->on_done(sub {
            return unless $weak && !$weak->{_closed};
            $weak->{_current_read} = undef;
            my $cb_result = $weak->_dispatch_frame($_[0]);
            if (Scalar::Util::blessed($cb_result) && $cb_result->isa('Future')) {
                # Consumer-opted backpressure: wait for their Future
                # before reading the next frame. Failures route to
                # on_error (same path as a raised callback exception).
                $cb_result->on_ready(sub {
                    return unless $weak && !$weak->{_closed};
                    my $res = shift;
                    if ($res->is_failed) {
                        $weak->_handle_fatal_error(
                            "on_message callback Future failed: " . $res->failure
                        );
                        return;
                    }
                    $weak_step->() if $weak_step && $weak && !$weak->{_closed};
                });
            } else {
                $weak_step->() if $weak_step && $weak && !$weak->{_closed};
            }
        });

        $f->on_fail(sub {
            return unless $weak;
            $weak->{_current_read} = undef;
            # If the user closed the subscription (or the underlying
            # client disconnected) while a read was in flight, a
            # "Connection closed by server" failure is expected, not
            # fatal. Short-circuit so we don't die through _handle_fatal_error.
            return if $weak->{_closed};
            $weak->_handle_fatal_error($_[0]);
        });
    };

    Scalar::Util::weaken($weak_step = $step);

    $self->{_driver_step} = $step;
    $step->();
    return;
}

# Backward-compatible wrapper
async sub next_message {
    my ($self) = @_;
    my $msg = await $self->next();
    return undef unless $msg;

    # Convert new format to old format for compatibility
    return {
        channel => $msg->{channel},
        message => $msg->{data},
        pattern => $msg->{pattern},
        type    => $msg->{type},
    };
}

# Internal: called when message arrives
sub _deliver_message {
    my ($self, $msg) = @_;

    if (@{$self->{_waiters}}) {
        # Someone is waiting - deliver directly
        my $waiter = shift @{$self->{_waiters}};
        $waiter->done($msg);
    }
    else {
        # Buffer the message
        push @{$self->{_message_queue}}, $msg;
    }
}

# Unsubscribe from specific channels
async sub unsubscribe {
    my ($self, @channels) = @_;

    return if $self->{_closed};

    my $redis = $self->{redis};

    if (@channels) {
        # Partial unsubscribe
        await $redis->_send_command('UNSUBSCRIBE', @channels);

        # Read confirmations
        for my $ch (@channels) {
            my $msg = await $redis->_read_pubsub_frame();
            $self->_remove_channel($ch);
        }
    }
    else {
        # Full unsubscribe - all channels
        my @all_channels = $self->channels;

        if (@all_channels) {
            await $redis->_send_command('UNSUBSCRIBE');

            # Read all confirmations
            for my $ch (@all_channels) {
                my $msg = await $redis->_read_pubsub_frame();
                $self->_remove_channel($ch);
            }
        }
    }

    # If no subscriptions remain, close and exit pubsub mode
    if ($self->channel_count == 0) {
        $self->_close;
    }

    return $self;
}

# Unsubscribe from patterns
async sub punsubscribe {
    my ($self, @patterns) = @_;

    return if $self->{_closed};

    my $redis = $self->{redis};

    if (@patterns) {
        await $redis->_send_command('PUNSUBSCRIBE', @patterns);

        for my $p (@patterns) {
            my $msg = await $redis->_read_pubsub_frame();
            $self->_remove_pattern($p);
        }
    }
    else {
        my @all_patterns = $self->patterns;

        if (@all_patterns) {
            await $redis->_send_command('PUNSUBSCRIBE');

            for my $p (@all_patterns) {
                my $msg = await $redis->_read_pubsub_frame();
                $self->_remove_pattern($p);
            }
        }
    }

    if ($self->channel_count == 0) {
        $self->_close;
    }

    return $self;
}

# Unsubscribe from sharded channels
async sub sunsubscribe {
    my ($self, @channels) = @_;

    return if $self->{_closed};

    my $redis = $self->{redis};

    if (@channels) {
        await $redis->_send_command('SUNSUBSCRIBE', @channels);

        for my $ch (@channels) {
            my $msg = await $redis->_read_pubsub_frame();
            $self->_remove_sharded_channel($ch);
        }
    }
    else {
        my @all = $self->sharded_channels;

        if (@all) {
            await $redis->_send_command('SUNSUBSCRIBE');

            for my $ch (@all) {
                my $msg = await $redis->_read_pubsub_frame();
                $self->_remove_sharded_channel($ch);
            }
        }
    }

    if ($self->channel_count == 0) {
        $self->_close;
    }

    return $self;
}

# Close subscription
sub _close {
    my ($self) = @_;

    $self->{_closed} = 1;
    $self->{redis}{in_pubsub} = 0;

    # Cancel any waiters
    for my $waiter (@{$self->{_waiters}}) {
        $waiter->done(undef) unless $waiter->is_ready;
    }
    $self->{_waiters} = [];

    # Release the driver closure; weak refs already broke the cycle,
    # so this is hygienic rather than required for GC.
    # Do NOT clear _current_read — the in-flight read Future must stay
    # pinned until it resolves, or F::AA will warn "lost its returning
    # future". on_done/on_fail will clear it when the read completes
    # and will see _closed first so they won't re-enter the driver.
    $self->{_driver_step} = undef;
}

sub is_closed { shift->{_closed} }

# Get all subscriptions for reconnect replay
sub get_replay_commands {
    my ($self) = @_;

    my @commands;

    my @channels = $self->channels;
    push @commands, ['SUBSCRIBE', @channels] if @channels;

    my @patterns = $self->patterns;
    push @commands, ['PSUBSCRIBE', @patterns] if @patterns;

    my @sharded = $self->sharded_channels;
    push @commands, ['SSUBSCRIBE', @sharded] if @sharded;

    return @commands;
}

1;

__END__

=encoding utf8

=head1 NAME

Async::Redis::Subscription - PubSub subscription handler

=head1 SYNOPSIS

    my $sub = await $redis->subscribe('channel1', 'channel2');

    while (my $msg = await $sub->next) {
        say "Channel: $msg->{channel}";
        say "Data: $msg->{data}";
    }

    await $sub->unsubscribe('channel1');
    await $sub->unsubscribe;  # all remaining

=head1 DESCRIPTION

Manages Redis PubSub subscriptions with async iterator pattern.

=head1 MESSAGE STRUCTURE

    {
        type    => 'message',      # or 'pmessage', 'smessage'
        channel => 'channel_name',
        pattern => 'pattern',      # defined for pmessage, undef otherwise
        data    => 'payload',
    }

The C<pattern> key is always present. It is defined for C<pmessage>
frames (the matching glob pattern) and C<undef> for C<message> and
C<smessage> frames. Consumers do not need C<exists $msg-E<gt>{pattern}>
checks.

C<next()> always returns real pub/sub messages. Reconnection is transparent.

=head1 RECONNECTION

When C<reconnect> is enabled on the Redis connection, subscriptions are
automatically re-established after a connection drop. To be notified:

    $sub->on_reconnect(sub {
        my ($sub) = @_;
        warn "Reconnected, may have lost messages";
        # re-poll state, log, etc.
    });

Messages published while the connection was down are lost (Redis pub/sub
has no persistence).

=head1 CALLBACK-DRIVEN DELIVERY

As an alternative to the C<await $sub-E<gt>next> iterator, you can
register a callback to receive messages:

    my $sub = await $redis->subscribe('chat');
    $sub->on_message(sub {
        my ($sub, $msg) = @_;
        # $msg has the same shape as next() returns:
        #   { type => 'message'|'pmessage'|'smessage',
        #     channel => ...,
        #     pattern => ...,  # defined for pmessage, undef otherwise
        #     data    => ... }
    });

Callback mode is designed for fire-and-forget listeners — background
dispatchers, websocket gateways, channel-layer middleware — where the
iterator pattern's requirement to be inside an awaited async sub is
awkward or triggers Future::AsyncAwait "lost its returning future"
warnings.

=head2 Exclusivity

Once C<on_message> is set on a Subscription, it is callback-mode for
the rest of its lifetime. Calls to C<< $sub->next >> will C<croak>.
This is sticky — there is no way to switch back. If you need iterator
mode, construct a new Subscription.

=head2 Signature

    $sub->on_message(sub {
        my ($subscription, $message) = @_;
        ...
    });

The callback receives the C<$subscription> itself as its first argument
(consistent with C<on_reconnect>), and the message hashref as its
second. The return value is normally ignored; if the return is a
C<Future>, see L</Backpressure>.

=head2 Backpressure

If your callback returns a C<Future>, the driver waits for that Future
to resolve before reading the next frame:

    $sub->on_message(async sub {
        my ($sub, $msg) = @_;
        await store_to_database($msg);    # driver waits before next read
    });

Synchronous callbacks (or callbacks returning non-Future values) do not
block the driver. This gives consumers opt-in backpressure with no
default overhead.

If the returned Future fails, the failure is routed to C<on_error>.

=head2 Fatal error handling

    $sub->on_error(sub {
        my ($sub, $err) = @_;
        ...
    });

C<on_error> fires when the underlying read encounters an error that
cannot be recovered by reconnect (e.g., reconnect is disabled, or
reconnect itself failed). After C<on_error> fires, the subscription is
closed and the driver stops.

B<If C<on_error> is not registered, fatal errors C<die>.> Silent death
of a pub/sub consumer is a debugging nightmare; loud-by-default
prevents it. If you genuinely want to swallow errors, register an
explicit no-op: C<< $sub->on_error(sub { }) >>.

Callback exceptions (dying inside C<on_message>) are also routed to
C<on_error>; the callback-died message is prepended to the error
string.

=head2 Ordering guarantee

Callbacks fire in the order frames arrive on the connection. No
concurrent invocation (Perl is single-threaded and the driver runs on
the event loop). After a reconnect, C<on_reconnect> always fires before
any post-reconnect C<on_message>.

=head2 Re-entrancy

Inside an C<on_message> callback you may safely:

=over 4

=item * Call C<< $sub->subscribe(...) >> — the new channel is added
cleanly; messages on it arrive via the same callback.

=item * Call C<< $sub->on_message($new_cb) >> — the current message is
dispatched to the previously-installed handler; the next frame uses
the new handler.

=item * C<die> — routed to C<on_error>.

=back

=head2 Backpressure and Redis server limits

Synchronous callbacks provide backpressure by blocking the driver loop:
while your callback runs, the driver doesn't read the next frame, so
TCP fills, Redis's output buffer grows. But Redis enforces
C<client-output-buffer-limit pubsub> (defaulting to S<32mb 8mb 60>
in recent versions) — if your subscriber cannot keep up for sustained
periods, B<Redis will disconnect you>. There is no amount of
client-side buffering that changes this: the limit is on the server.

If your processing is genuinely slow, return a Future from your
callback (enabling opt-in backpressure above) AND consider moving the
expensive work to a worker pool so the callback can return quickly.
Long synchronous processing in pub/sub callbacks is an anti-pattern at
scale regardless of client.

=cut
