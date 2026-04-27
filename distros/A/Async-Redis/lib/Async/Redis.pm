package Async::Redis;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.002000';

use Future;
use Future::AsyncAwait;
use Future::IO 0.23;
use Future::Selector 0.05;
use Scalar::Util qw(blessed weaken);
use Socket qw(pack_sockaddr_in pack_sockaddr_un inet_aton AF_INET AF_UNIX SOCK_STREAM);
use IO::Handle ();
use IO::Socket::INET;
use Time::HiRes ();

# Error classes
use Async::Redis::Error::Connection;
use Async::Redis::Error::Timeout;
use Async::Redis::Error::Disconnected;
use Async::Redis::Error::Redis;
use Async::Redis::Error::Protocol;

# Import auto-generated command methods
use Async::Redis::Commands;
our @ISA = qw(Async::Redis::Commands);

# Key extraction for prefixing
use Async::Redis::KeyExtractor;

# Transaction support
use Async::Redis::Transaction;

# Script support
use Async::Redis::Script;

# Iterator support
use Async::Redis::Iterator;

# Pipeline support
use Async::Redis::Pipeline;
use Async::Redis::AutoPipeline;

# PubSub support
use Async::Redis::Subscription;

# Telemetry support
use Async::Redis::Telemetry;

# Try XS version first, fall back to pure Perl
BEGIN {
    eval { require Protocol::Redis::XS; 1 }
        or require Protocol::Redis;
}

sub _parser_class {
    return $INC{'Protocol/Redis/XS.pm'} ? 'Protocol::Redis::XS' : 'Protocol::Redis';
}

sub _calculate_backoff {
    my ($self, $attempt) = @_;

    # Exponential: delay * 2^(attempt-1)
    my $delay = $self->{reconnect_delay} * (2 ** ($attempt - 1));

    # Cap at max
    $delay = $self->{reconnect_delay_max} if $delay > $self->{reconnect_delay_max};

    # Apply jitter: delay * (1 +/- jitter)
    if ($self->{reconnect_jitter} > 0) {
        my $jitter_range = $delay * $self->{reconnect_jitter};
        my $jitter = (rand(2) - 1) * $jitter_range;
        $delay += $jitter;
    }

    return $delay;
}

# Free function, not a method. Call as _await_with_deadline($f, $deadline).
# Race a read future against a deadline. Returns a Future resolving to
# ($read_future, $timed_out_bool). The caller inspects $timed_out and
# $read_future->is_failed explicitly; we never throw from here.
#
# On timeout win: $read_future is left pending. _reader_fatal is the sole
# owner of its cancellation (it must happen before _close_socket so
# Future::IO unregisters while fileno is still valid).
# On read win: the internal timeout timer is cancelled here for hygiene.
sub _await_with_deadline {
    my ($read_f, $deadline) = @_;

    if (!defined $deadline) {
        return $read_f->followed_by(sub { Future->done($read_f, 0) });
    }

    my $remaining = $deadline - Time::HiRes::time();
    if ($remaining <= 0) {
        return Future->done($read_f, 1);
    }

    my $timeout_f = Future::IO->sleep($remaining)
        ->then(sub { Future->fail('__deadline__') });

    # Use without_cancel so that if timeout wins, wait_any's cancel of the
    # losing future does not propagate to $read_f (caller owns its lifecycle).
    return Future->wait_any($read_f->without_cancel, $timeout_f)
        ->followed_by(sub {
            my ($f) = @_;
            my $timed_out = $f->is_failed
                && (($f->failure)[0] // '') eq '__deadline__' ? 1 : 0;

            if (!$timed_out && !$timeout_f->is_ready) {
                $timeout_f->cancel;
            }

            return Future->done($read_f, $timed_out);
        });
}

sub new {
    my ($class, %args) = @_;

    # Parse URI if provided
    if ($args{uri}) {
        require Async::Redis::URI;
        my $uri = Async::Redis::URI->parse($args{uri});
        if ($uri) {
            my %uri_args = $uri->to_hash;
            # URI values are defaults, explicit args override
            %args = (%uri_args, %args);
            delete $args{uri};  # don't store the string
        }
    }

    my $self = bless {
        path     => $args{path},
        host     => $args{path} ? undef : ($args{host} // 'localhost'),
        port     => $args{path} ? undef : ($args{port} // 6379),
        socket   => undef,
        parser   => undef,
        connected          => 0,
        _socket_live       => 0,
        _fatal_in_progress => 0,
        _reader_running    => 0,   # dedup guard; the selector owns the reader Future itself
        _write_lock        => undef,     # will be a Future used as a lock, populated lazily
        _reconnect_future  => undef,
        _tasks             => Future::Selector->new,

        # Timeout settings
        connect_timeout         => $args{connect_timeout} // 10,
        request_timeout         => $args{request_timeout} // 5,
        blocking_timeout_buffer => $args{blocking_timeout_buffer} // 2,

        # Inflight tracking with deadlines
        # Entry: { future => $f, cmd => $cmd, args => \@args, deadline => $t, sent_at => $t }
        inflight => [],

        # Reconnection settings
        reconnect              => $args{reconnect} // 0,
        reconnect_delay        => $args{reconnect_delay} // 0.1,
        reconnect_delay_max    => $args{reconnect_delay_max} // 60,
        reconnect_jitter       => $args{reconnect_jitter} // 0.25,
        reconnect_max_attempts => $args{reconnect_max_attempts} // 10,  # 0 = unlimited
        _reconnect_attempt     => 0,

        # Callbacks
        on_connect    => $args{on_connect},
        on_disconnect => $args{on_disconnect},
        on_error      => $args{on_error},

        # Authentication
        password    => $args{password},
        username    => $args{username},
        database    => $args{database} // 0,
        client_name => $args{client_name},

        # TLS
        tls => $args{tls},

        # Key prefixing
        prefix => $args{prefix},

        # Pipeline settings
        pipeline_depth => $args{pipeline_depth} // 10000,
        auto_pipeline  => $args{auto_pipeline} // 0,

        # Backpressure: max queued messages before _dispatch_frame's slot wait blocks.
        message_queue_depth => do {
            my $d = $args{message_queue_depth} // 1;
            die "message_queue_depth must be >= 1 (got $d)" if $d < 1;
            $d;
        },

        # Transaction state
        in_multi => 0,
        watching => 0,

        # PubSub state
        in_pubsub     => 0,
        _subscription => undef,
        _pump_running => 0,

        # Fork safety
        _pid => $$,

        # Script registry
        _scripts => {},

        # Current read future for clean disconnect cancellation
        _current_read_future => undef,

        # Telemetry options
        debug              => $args{debug},
        otel_tracer        => $args{otel_tracer},
        otel_meter         => $args{otel_meter},
        otel_include_args  => $args{otel_include_args} // 0,
        otel_redact        => $args{otel_redact} // 1,
    }, $class;

    # Initialize telemetry if any observability enabled
    if ($self->{debug} || $self->{otel_tracer} || $self->{otel_meter}) {
        $self->{_telemetry} = Async::Redis::Telemetry->new(
            tracer       => $self->{otel_tracer},
            meter        => $self->{otel_meter},
            debug        => $self->{debug},
            include_args => $self->{otel_include_args},
            redact       => $self->{otel_redact},
            host         => $self->{host},
            port         => $self->{port},
            database     => $self->{database} // 0,
        );
    }

    return $self;
}

# Connect to Redis server
async sub connect {
    my ($self) = @_;

    return $self if $self->{connected};

    # Create socket — AF_UNIX for path, AF_INET for host:port
    my ($socket, $sockaddr);

    if ($self->{path}) {
        socket($socket, AF_UNIX, SOCK_STREAM, 0)
            or die Async::Redis::Error::Connection->new(
                message => "Cannot create unix socket: $!",
                host    => $self->{path},
                port    => 0,
            );
        IO::Handle::blocking($socket, 0);
        $sockaddr = pack_sockaddr_un($self->{path});
    } else {
        $socket = IO::Socket::INET->new(
            Proto    => 'tcp',
            Blocking => 0,
        ) or die Async::Redis::Error::Connection->new(
            message => "Cannot create socket: $!",
            host    => $self->{host},
            port    => $self->{port},
        );

        # Build sockaddr
        my $addr = inet_aton($self->{host})
            or die Async::Redis::Error::Connection->new(
                message => "Cannot resolve host: $self->{host}",
                host    => $self->{host},
                port    => $self->{port},
            );
        $sockaddr = pack_sockaddr_in($self->{port}, $addr);
    }

    # Connect with timeout using Future->wait_any
    my $connect_f = Future::IO->connect($socket, $sockaddr);
    my $sleep_f = Future::IO->sleep($self->{connect_timeout});

    my $timeout_f = $sleep_f->then(sub {
        return Future->fail('connect_timeout');
    });

    my $wait_f = Future->wait_any($connect_f, $timeout_f);

    # Use followed_by to handle both success and failure without await propagating failure
    my $result_f = $wait_f->followed_by(sub {
        my ($f) = @_;
        return Future->done($f);  # wrap the future itself
    });

    my $completed_f = await $result_f;

    # Now check the result
    if ($completed_f->is_failed) {
        my ($error) = $completed_f->failure;
        # Don't call close() - let $socket go out of scope when we die.
        # Perl's DESTROY will close it after the exception unwinds.

        if ($error eq 'connect_timeout') {
            die Async::Redis::Error::Timeout->new(
                message => "Connect timed out after $self->{connect_timeout}s",
                timeout => $self->{connect_timeout},
            );
        }
        die Async::Redis::Error::Connection->new(
            message => "$error",
            host    => $self->{path} // $self->{host},
            port    => $self->{port} // 0,
        );
    }

    # TLS upgrade if enabled
    if ($self->{tls}) {
        eval {
            $socket = await $self->_tls_upgrade($socket);
        };
        if ($@) {
            # Don't call close() - let $socket go out of scope when we die.
            # Perl's DESTROY will close it after the exception unwinds.
            die $@;
        }
    }

    $self->{socket} = $socket;
    $self->{parser} = _parser_class()->new(api => 1);
    $self->{_socket_live} = 1;   # write gate and reader can now submit
    $self->{inflight} = [];
    $self->{_pid} = $$;  # Track PID for fork safety
    $self->{_current_read_future} = undef;

    # Run Redis protocol handshake (AUTH, SELECT, CLIENT SETNAME).
    # connected stays 0 during handshake; set it only on success so
    # callers never see a half-initialised object.
    my $handshake_ok = eval { await $self->_redis_handshake; 1 };
    unless ($handshake_ok) {
        my $err = $@;
        $self->_reset_connection('handshake_failure');
        die $err;
    }

    $self->{connected} = 1;

    # Initialize auto-pipeline if enabled
    if ($self->{auto_pipeline}) {
        $self->{_auto_pipeline} = Async::Redis::AutoPipeline->new(
            redis     => $self,
            max_depth => $self->{pipeline_depth},
        );
    }

    # Fire on_connect callback and reset reconnect counter
    if ($self->{on_connect}) {
        $self->{on_connect}->($self);
    }
    $self->{_reconnect_attempt} = 0;

    # Telemetry: record connection
    if ($self->{_telemetry}) {
        $self->{_telemetry}->record_connection(1);
        $self->{_telemetry}->log_event('connected',
            $self->{path} // "$self->{host}:$self->{port}");
    }

    return $self;
}

# Redis protocol handshake after TCP connect
async sub _redis_handshake {
    my ($self) = @_;

    # Use connect_timeout for the entire handshake (AUTH, SELECT, CLIENT SETNAME)
    # This ensures the handshake can't block forever if Redis hangs
    my $deadline = Time::HiRes::time() + $self->{connect_timeout};

    # AUTH (password or username+password for ACL)
    if (defined $self->{password}) {
        my @auth_args = ('AUTH');
        push @auth_args, $self->{username} if defined $self->{username};
        push @auth_args, $self->{password};

        my $cmd = $self->_build_command(@auth_args);
        await $self->_send($cmd);

        my $response = await $self->_read_response_with_deadline($deadline, ['AUTH']);
        my $result = $self->_decode_response($response);

        # AUTH returns OK on success, throws on failure
        unless ($result && $result eq 'OK') {
            die Async::Redis::Error::Redis->new(
                message => "Authentication failed: $result",
                type    => 'NOAUTH',
            );
        }
    }

    # SELECT database
    if ($self->{database} && $self->{database} != 0) {
        my $cmd = $self->_build_command('SELECT', $self->{database});
        await $self->_send($cmd);

        my $response = await $self->_read_response_with_deadline($deadline, ['SELECT', $self->{database}]);
        my $result = $self->_decode_response($response);

        unless ($result && $result eq 'OK') {
            die Async::Redis::Error::Redis->new(
                message => "SELECT failed: $result",
                type    => 'ERR',
            );
        }
    }

    # CLIENT SETNAME
    if (defined $self->{client_name} && length $self->{client_name}) {
        my $cmd = $self->_build_command('CLIENT', 'SETNAME', $self->{client_name});
        await $self->_send($cmd);

        my $response = await $self->_read_response_with_deadline($deadline, ['CLIENT', 'SETNAME']);
        # Ignore result - SETNAME failing shouldn't prevent connection
    }
}

# Check if connected to Redis
sub is_connected {
    my ($self) = @_;
    return $self->{connected} ? 1 : 0;
}

# Disconnect from Redis — user-initiated path.
#
# Distinct from _reader_fatal (which handles stream-level failure): this
# path is deterministic for user context. Key differences:
#   - Inflight futures fail with Async::Redis::Error::Disconnected
#     ("Client disconnect") rather than Connection ("Connection closed
#     by peer"). Callers can distinguish "I disconnected" from "the
#     server/network dropped me."
#   - Subscription gets _close (clean; iterator next() returns undef,
#     callback driver exits cleanly) rather than _fail_fatal.
#   - No reconnect handoff — disconnect means stay down.
#
# Relationship to the selector (_tasks): this method does explicit
# teardown rather than relying on _reader_fatal propagation. Any tasks
# still in the selector (e.g., in-flight reconnect, autopipeline submit)
# will see their underlying I/O fail when the socket is closed and
# unwind via their existing on_fail handlers. Cancelling them explicitly
# would be cleaner but requires Future::Selector API that doesn't yet
# exist; this is acceptable because the failing I/O is a deterministic
# wakeup.
sub disconnect {
    my ($self) = @_;
    return $self unless $self->{_socket_live} || $self->{connected};

    my $was_connected = $self->{connected};

    # Close subscription cleanly before socket close so the pubsub branch
    # in any subsequent _reader_fatal (triggered by the failing read)
    # sees _closed and no-ops on _fail_fatal.
    if (my $sub = $self->{_subscription}) {
        $sub->_close unless $sub->is_closed;
    }

    # Detach inflight + auto-pipeline queue before socket close so
    # _close_socket doesn't cancel them — we will fail them explicitly
    # with a user-context error type.
    my $detached_inflight = $self->{inflight};
    $self->{inflight} = [];
    my $detached_autopipe = [];
    if (my $ap = $self->{_auto_pipeline}) {
        $detached_autopipe = $ap->_detach_queued;
    }

    # Cancel current read BEFORE closing socket so Future::IO can
    # unregister its watcher while fileno is still valid.
    if ($self->{_current_read_future}
        && !$self->{_current_read_future}->is_ready) {
        $self->{_current_read_future}->cancel;
    }
    $self->{_current_read_future} = undef;

    # Cancel any in-flight reconnect task so it doesn't re-establish
    # state (connecting a new socket, setting _socket_live=1) after the
    # user has intentionally disconnected.
    if (my $rf = delete $self->{_reconnect_future}) {
        $rf->cancel unless $rf->is_ready;
    }

    my $err = Async::Redis::Error::Disconnected->new(
        message => "Client disconnect",
    );

    # Wake the write-gate chain. Any commands waiting in
    # _acquire_write_lock's `await $prev` unwind via their await
    # throwing, and their _execute_command eval rethrows Disconnected
    # to the caller. Without this, write-gate waiters stay suspended
    # because the normal release path only runs when the current
    # holder's body completes.
    if (my $lock = delete $self->{_write_lock}) {
        $lock->fail($err) unless $lock->is_ready;
    }

    $self->_close_socket if $self->{socket};
    $self->{_socket_live}       = 0;
    $self->{_fatal_in_progress} = 0;
    $self->{_reader_running}    = 0;
    $self->{connected}          = 0;
    $self->{parser}             = undef;
    $self->{in_pubsub}          = 0;

    # Fail detached futures with the user-context type so callers can
    # distinguish "I disconnected" from Connection/EOF.
    for my $entry (@$detached_inflight, @$detached_autopipe) {
        next if $entry->{future}->is_ready;
        $entry->{future}->fail($err);
    }

    # on_disconnect + telemetry fire only if we were publicly connected,
    # mirroring _reader_fatal's guard so a failed initial handshake
    # doesn't spuriously emit these.
    if ($was_connected && $self->{on_disconnect}) {
        $self->{on_disconnect}->($self, 'client disconnect');
    }
    if ($was_connected && $self->{_telemetry}) {
        $self->{_telemetry}->record_connection(-1);
        $self->{_telemetry}->log_event('disconnected', 'client disconnect');
    }

    return $self;
}

# Destructor - clean up socket when object is garbage collected
sub DESTROY {
    my ($self) = @_;
    # Only clean up if we have a socket and it's still open
    if ($self->{socket} && fileno($self->{socket})) {
        $self->_close_socket;
    }
}

# Properly close socket, canceling any pending futures first
sub _close_socket {
    my ($self) = @_;

    # Take ownership - removes from $self immediately
    my $socket = delete $self->{socket} or return;
    my $fileno = fileno($socket);

    # Cancel any pending inflight futures - this propagates to
    # Future::IO internals and cleans up any watchers on this socket.
    # Important: must happen while fileno is still valid!
    if (my $inflight = delete $self->{inflight}) {
        for my $entry (@$inflight) {
            if ($entry->{future} && !$entry->{future}->is_ready) {
                $entry->{future}->cancel;
            }
        }
    }
    $self->{inflight} = [];

    # Initiate clean TCP shutdown (FIN) while fileno still valid
    shutdown($socket, 2) if defined $fileno;

    # DON'T call close()!
    # $socket falls out of scope here, Perl's DESTROY calls close().
    # By this point, Future::IO has already unregistered its watchers
    # via the cancel() calls above.
}

# Check if fork occurred and invalidate connection
sub _check_fork {
    my ($self) = @_;

    if ($self->{_pid} && $self->{_pid} != $$) {
        # Fork detected - invalidate connection (parent owns the socket)
        # Don't cancel futures - they belong to the parent's event loop
        # Just clear references so we don't try to use them
        $self->{connected}    = 0;
        $self->{_socket_live} = 0;
        $self->{socket} = undef;
        $self->{parser} = undef;
        $self->{inflight} = [];
        $self->{_current_read_future} = undef;  # Clear stale reference

        my $old_pid = $self->{_pid};
        $self->{_pid} = $$;

        if ($self->{_telemetry}) {
            $self->{_telemetry}->log_event('fork_detected', "old PID: $old_pid, new PID: $$");
        }

        return 1;  # Fork occurred
    }

    return 0;
}

# Build Redis command in RESP format
sub _build_command {
    my ($self, @args) = @_;

    my $cmd = "*" . scalar(@args) . "\r\n";
    for my $arg (@args) {
        $arg //= '';
        my $bytes = "$arg";  # stringify
        utf8::encode($bytes) if utf8::is_utf8($bytes);
        $cmd .= "\$" . length($bytes) . "\r\n" . $bytes . "\r\n";
    }
    return $cmd;
}

# Send raw data
async sub _send {
    my ($self, $data) = @_;
    await Future::IO->write_exactly($self->{socket}, $data);
    return length($data);
}

# Add command to inflight queue - returns queue depth.
# redis_error_policy: 'fail' (default) fails the future on -ERR frames;
# 'capture' calls ->done($err_obj) so callers can inspect per-slot errors
# (used by pipelining in Task N+).
sub _add_inflight {
    my ($self, $future, $cmd, $args, $deadline, $redis_error_policy) = @_;
    push @{$self->{inflight}}, {
        future      => $future,
        cmd         => $cmd,
        args        => $args,
        deadline    => $deadline,
        redis_error => $redis_error_policy // 'fail',
        sent_at     => Time::HiRes::time(),
    };
    return scalar @{$self->{inflight}};
}

# Shift first entry from inflight queue
sub _shift_inflight {
    my ($self) = @_;
    return shift @{$self->{inflight}};
}

# Fail all pending inflight futures with given error
sub _fail_all_inflight {
    my ($self, $error) = @_;
    while (my $entry = $self->_shift_inflight) {
        if ($entry->{future} && !$entry->{future}->is_ready) {
            $entry->{future}->fail($error);
        }
    }
}

# The single socket reader. Runs while there is work (inflight or pubsub).
# Calls _reader_fatal on any stream-alignment failure. The selector
# (_tasks) owns this task; _reader_running is cleared on every exit path
# via on_ready so _ensure_reader can restart it on the next submission.
async sub _run_reader {
    my ($self) = @_;

    while (1) {
        # Exit conditions.
        return unless $self->{_socket_live};
        last if !$self->{in_pubsub} && !@{$self->{inflight}};
        last if $self->{in_pubsub} && !$self->{_subscription};

        my $head = $self->{inflight}[0];
        my $deadline = $head ? $head->{deadline} : undef;

        # Set up read future; track so _reader_fatal can cancel it.
        my $read_f = Future::IO->read($self->{socket}, 65536);
        $self->{_current_read_future} = $read_f;

        my ($returned_f, $timed_out) = await _await_with_deadline($read_f, $deadline);

        # Clear slot on success path; fatal clears it on timeout/cancel.
        $self->{_current_read_future} = undef
            if !$timed_out && $returned_f->is_ready && !$returned_f->is_failed;

        if ($timed_out) {
            my $err = Async::Redis::Error::Timeout->new(
                message        => "Request timed out",
                command        => $head ? $head->{args} : undef,
                timeout        => $self->{request_timeout},
                maybe_executed => 1,
            );
            $self->_reader_fatal($err);
            return;
        }

        if ($returned_f->is_failed) {
            my ($rerr) = $returned_f->failure;
            my $err = Async::Redis::Error::Connection->new(
                message => "Connection read error: $rerr",
                host    => $self->{host},
                port    => $self->{port},
            );
            $self->_reader_fatal($err);
            return;
        }

        my $buf = $returned_f->get;
        if (!defined $buf || length($buf) == 0) {
            my $err = Async::Redis::Error::Connection->new(
                message => "Connection closed by peer",
                host    => $self->{host},
                port    => $self->{port},
            );
            $self->_reader_fatal($err);
            return;
        }

        $self->{parser}->parse($buf);

        # Drain all complete messages the parser has.
        while (my $msg = $self->{parser}->get_message) {
            my ($kind, $value) = $self->_decode_response_result($msg);

            if ($kind eq 'protocol_error') {
                $self->_reader_fatal($value);
                return;
            }

            my $is_pubsub_message = 0;
            if ($self->{in_pubsub} && $kind eq 'ok' && ref($value) eq 'ARRAY') {
                my $frame_name = $value->[0] // '';
                $is_pubsub_message = 1
                    if $frame_name eq 'message'
                    || $frame_name eq 'pmessage'
                    || $frame_name eq 'smessage';
            }

            if ($is_pubsub_message) {
                my $sub = $self->{_subscription};
                if (!$sub) {
                    # No active subscription but got a message frame: strict desync.
                    $self->_reader_fatal(
                        Async::Redis::Error::Protocol->new(
                            message => "message frame but no active subscription",
                        )
                    );
                    return;
                }
                # _dispatch_frame is sync today (returns undef) and will become
                # async in Task 15 (returning a Future for backpressure). Await
                # only if we got a Future back.
                my $dispatch_result = $sub->_dispatch_frame($value);
                if (blessed($dispatch_result) && $dispatch_result->isa('Future')) {
                    await $dispatch_result;
                }
                next;
            }

            if (!@{$self->{inflight}}) {
                # Strict: unexpected frame with empty inflight = desync.
                $self->_reader_fatal(
                    Async::Redis::Error::Protocol->new(
                        message => "unexpected frame (kind=$kind) with empty inflight",
                    )
                );
                return;
            }

            my $entry = shift @{$self->{inflight}};
            if ($kind eq 'redis_error') {
                if (($entry->{redis_error} // 'fail') eq 'capture') {
                    $entry->{future}->done($value) unless $entry->{future}->is_ready;
                } else {
                    $entry->{future}->fail($value) unless $entry->{future}->is_ready;
                }
            } else {
                $entry->{future}->done($value) unless $entry->{future}->is_ready;
            }
        }
    }
}

# Start the reader if not already running. Idempotent.
#
# Ownership: the reader Future lives in $self->{_tasks} (a Future::Selector).
# The selector holds the strong reference and auto-removes the item on
# completion. $self->{_reader_running} is a boolean dedup guard — it's NOT
# a second source of truth about ownership, only a "is one already running?"
# flag that's cheap to check without peeking at selector internals.
#
# Failure propagation: because the reader is in the selector, any awaiting
# caller using $self->{_tasks}->run_until_ready($their_future) will see the
# reader's failure propagated to them. That's the structured-concurrency
# guarantee — no hanging callers when the reader dies unhandled.
sub _ensure_reader {
    my ($self) = @_;
    return if $self->{_reader_running};
    $self->{_reader_running} = 1;
    my $f = $self->_run_reader;
    $f->on_ready(sub { $self->{_reader_running} = 0 });
    $self->{_tasks}->add(data => 'reader', f => $f);
    return;
}

# Read and parse one response
async sub _read_response {
    my ($self) = @_;

    # First check if parser already has a complete message
    # (from previous read that contained multiple responses)
    if (my $msg = $self->{parser}->get_message) {
        return $msg;
    }

    # Read until we get a complete message
    while (1) {
        my $buf = await Future::IO->read($self->{socket}, 65536);

        # EOF
        if (!defined $buf || length($buf) == 0) {
            die "Connection closed by server";
        }

        $self->{parser}->parse($buf);

        if (my $msg = $self->{parser}->get_message) {
            return $msg;
        }
    }
}

# Dispatch table mapping each blocking command to how its timeout is encoded.
# position: 'last'         => final argument (seconds)
# position: N (integer)    => argument at index N (seconds, unless unit=>'ms')
# position: 'block_option' => scan for BLOCK keyword, next arg is timeout (ms)
# unit: 'ms'               => divide raw value by 1000 to get seconds
# A timeout of zero means "block indefinitely" — no client-side deadline.
my %BLOCKING_TIMEOUT = (
    BLPOP      => { position => 'last' },
    BRPOP      => { position => 'last' },
    BRPOPLPUSH => { position => 'last' },
    BLMOVE     => { position => 'last' },
    BZPOPMIN   => { position => 'last' },
    BZPOPMAX   => { position => 'last' },
    BLMPOP     => { position => 0 },
    BZMPOP     => { position => 0 },
    XREAD      => { position => 'block_option', unit => 'ms' },
    XREADGROUP => { position => 'block_option', unit => 'ms' },
    WAIT       => { position => 'last', unit => 'ms' },
    WAITAOF    => { position => 'last', unit => 'ms' },
);

# Calculate deadline based on command type
sub _calculate_deadline {
    my ($self, $cmd, @args) = @_;
    $cmd = uc($cmd // '');

    my $spec = $BLOCKING_TIMEOUT{$cmd};
    if (!$spec) {
        return Time::HiRes::time() + $self->{request_timeout};
    }

    my $raw;
    my $pos = $spec->{position};

    if ($pos eq 'last') {
        $raw = $args[-1];
    }
    elsif ($pos eq 'block_option') {
        for my $i (0 .. $#args - 1) {
            if (uc($args[$i] // '') eq 'BLOCK') {
                $raw = $args[$i + 1];
                last;
            }
        }
        # No BLOCK option found — non-blocking variant; use request_timeout
        return Time::HiRes::time() + $self->{request_timeout}
            unless defined $raw;
    }
    else {
        # Numeric index into @args
        $raw = $args[$pos];
    }

    if (!defined $raw || $raw !~ /^-?\d+(?:\.\d+)?$/) {
        warn "_calculate_deadline: non-numeric timeout for $cmd; falling back to request_timeout\n";
        return Time::HiRes::time() + $self->{request_timeout};
    }

    my $seconds = ($spec->{unit} // 'seconds') eq 'ms'
        ? $raw / 1000
        : $raw + 0;

    # Zero means block indefinitely — no client-side deadline
    return undef if $seconds == 0;

    return Time::HiRes::time() + $seconds + $self->{blocking_timeout_buffer};
}

sub _ssl_verify_peer {
    require IO::Socket::SSL;
    return IO::Socket::SSL::SSL_VERIFY_PEER();
}

sub _ssl_verify_none {
    require IO::Socket::SSL;
    return IO::Socket::SSL::SSL_VERIFY_NONE();
}

# Build the IO::Socket::SSL option hash for the current connection.
# Handles chain verification, SNI, hostname identity checking, and
# client cert/key/CA forwarding. Called by _tls_upgrade and directly
# by unit tests.
sub _build_tls_options {
    my ($self) = @_;
    my %ssl_opts = (SSL_startHandshake => 0);

    my $tls      = $self->{tls};
    my $tls_hash = ref $tls eq 'HASH' ? $tls : {};

    my $verify          = exists $tls_hash->{verify}          ? !!$tls_hash->{verify}          : 1;
    my $verify_hostname = exists $tls_hash->{verify_hostname} ? !!$tls_hash->{verify_hostname} : 1;

    $ssl_opts{SSL_ca_file}   = $tls_hash->{ca_file}   if $tls_hash->{ca_file};
    $ssl_opts{SSL_cert_file} = $tls_hash->{cert_file} if $tls_hash->{cert_file};
    $ssl_opts{SSL_key_file}  = $tls_hash->{key_file}  if $tls_hash->{key_file};

    if ($verify) {
        $ssl_opts{SSL_verify_mode} = $self->_ssl_verify_peer;
        $ssl_opts{SSL_hostname}    = $self->{host};

        if ($verify_hostname) {
            $ssl_opts{SSL_verifycn_name}   = $self->{host};
            $ssl_opts{SSL_verifycn_scheme} = 'default';
        }
    } else {
        $ssl_opts{SSL_verify_mode} = $self->_ssl_verify_none;
    }

    return %ssl_opts;
}

# Non-blocking TLS upgrade
async sub _tls_upgrade {
    my ($self, $socket) = @_;

    require IO::Socket::SSL;

    my %ssl_opts = $self->_build_tls_options;

    # Start SSL (does not block because SSL_startHandshake => 0)
    IO::Socket::SSL->start_SSL($socket, %ssl_opts)
        or die Async::Redis::Error::Connection->new(
            message => "SSL setup failed: " . IO::Socket::SSL::errstr(),
            host    => $self->{host},
            port    => $self->{port},
        );

    # Drive handshake with non-blocking loop
    my $deadline = Time::HiRes::time() + $self->{connect_timeout};

    while (1) {
        # Check timeout
        if (Time::HiRes::time() >= $deadline) {
            die Async::Redis::Error::Timeout->new(
                message => "TLS handshake timed out",
                timeout => $self->{connect_timeout},
            );
        }

        # Attempt handshake step
        my $rv = $socket->connect_SSL;

        if ($rv) {
            # Handshake complete!
            return $socket;
        }

        # Check what the handshake needs
        my $remaining = $deadline - Time::HiRes::time();
        $remaining = 0.1 if $remaining <= 0;

        if ($IO::Socket::SSL::SSL_ERROR == IO::Socket::SSL::SSL_ERROR_WANT_READ()) {
            # Wait for socket to become readable with timeout
            my $read_f = Future::IO->waitfor_readable($socket);
            my $timeout_f = Future::IO->sleep($remaining)->then(sub {
                return Future->fail('tls_timeout');
            });

            my $wait_f = Future->wait_any($read_f, $timeout_f);
            await $wait_f;

            if ($wait_f->is_failed) {
                die Async::Redis::Error::Timeout->new(
                    message => "TLS handshake timed out",
                    timeout => $self->{connect_timeout},
                );
            }
        }
        elsif ($IO::Socket::SSL::SSL_ERROR == IO::Socket::SSL::SSL_ERROR_WANT_WRITE()) {
            # Wait for socket to become writable with timeout
            my $write_f = Future::IO->waitfor_writable($socket);
            my $timeout_f = Future::IO->sleep($remaining)->then(sub {
                return Future->fail('tls_timeout');
            });

            my $wait_f = Future->wait_any($write_f, $timeout_f);
            await $wait_f;

            if ($wait_f->is_failed) {
                die Async::Redis::Error::Timeout->new(
                    message => "TLS handshake timed out",
                    timeout => $self->{connect_timeout},
                );
            }
        }
        else {
            # Actual error
            die Async::Redis::Error::Connection->new(
                message => "TLS handshake failed: " . IO::Socket::SSL::errstr(),
                host    => $self->{host},
                port    => $self->{port},
            );
        }
    }
}

# Reconnect with exponential backoff
async sub _reconnect {
    my ($self) = @_;

    my $max = $self->{reconnect_max_attempts};
    my $attempt = 0;

    while (!$self->{connected}) {
        $attempt++;
        $self->{_reconnect_attempt} = $attempt;

        my $ok = eval {
            await $self->connect;
            1;
        };

        if ($ok) {
            $self->{_reconnect_attempt} = 0;
            last;
        }

        my $error = $@;

        # Fire on_error callback
        if ($self->{on_error}) {
            $self->{on_error}->($self, $error);
        }

        # Honor reconnect_max_attempts cap so an unreachable Redis
        # doesn't spin forever. 0 means unlimited.
        if ($max && $attempt >= $max) {
            $self->{_reconnect_attempt} = 0;
            die Async::Redis::Error::Disconnected->new(
                message => "Reconnect gave up after $max attempts",
            );
        }

        my $delay = $self->_calculate_backoff($attempt);
        await Future::IO->sleep($delay);
    }

    # Reset attempt counter on success so subsequent reconnects start fresh.
    $self->{_reconnect_attempt} = 0;
}

# Ensure the socket is live, reconnecting if configured.
#
# Dedup: $self->{_reconnect_future} is the Future for the in-flight
# reconnect. Concurrent callers share it. The slot is the shared-await
# signal, NOT the ownership — ownership lives in $self->{_tasks}.
#
# Structured-concurrency: the reconnect task is added to the selector
# so any caller currently awaiting via run_until_ready sees reconnect
# failures propagated.
#
# NOTE: dedup is race-safe only when called from inside the write
# gate (which serialises callers). Outside the gate, a failed reconnect
# could be observed after on_ready clears the slot, allowing a second
# reconnect to start before state converges.
async sub _ensure_connected {
    my ($self) = @_;
    return if $self->{_socket_live};
    if (my $f = $self->{_reconnect_future}) {
        await $f;
        return;
    }
    my $f = $self->_reconnect;
    $self->{_reconnect_future} = $f;
    $self->{_tasks}->add(data => 'reconnect', f => $f);
    $f->on_ready(sub { $self->{_reconnect_future} = undef });
    await $f;
}

# Reconnect and replay pubsub subscriptions
async sub _reconnect_pubsub {
    my ($self) = @_;

    my $sub = $self->{_subscription}
        or die Async::Redis::Error::Disconnected->new(
            message => "No subscription to replay",
        );

    my @replay = $sub->get_replay_commands;

    # Ensure connection state is fully cleaned up before reconnecting.
    # _reset_connection may have already been called by _read_response,
    # but if the socket was closed externally, we need to clean up
    # stale IO watchers and state here. It is safe to call twice —
    # the on_disconnect callback is guarded by $was_connected.
    $self->_reset_connection('pubsub_reconnect');

    await $self->_reconnect;

    # Re-enter pubsub mode before replaying so the unified reader
    # classifies incoming message frames correctly during replay.
    $self->{in_pubsub} = 1;

    # Replay all subscription commands through the write gate and unified
    # reader. Each channel/pattern gets its own command so confirmations
    # are matched one-to-one via the inflight queue.
    for my $cmd (@replay) {
        my ($command, @args) = @$cmd;
        for my $arg (@args) {
            await $self->_pubsub_command($command, $arg);
        }
    }
}

# Asynchronously reconnect after a pubsub connection drop. Called by
# _reader_fatal when reconnect is enabled and a subscription is active.
# Fires _resume_after_reconnect on the subscription on success, or
# _fail_fatal on unrecoverable reconnect failure.
sub _reconnect_async {
    my ($self, $sub) = @_;

    # Dedup against any reconnect already in progress (from either this
    # path or _ensure_connected). The slot is the shared signal.
    return if $self->{_reconnect_future}
        && !$self->{_reconnect_future}->is_ready;

    weaken(my $weak_self = $self);
    weaken(my $weak_sub  = $sub);

    my $f = (async sub {
        # Reconnect the socket. _reconnect handles retry/backoff and
        # dies with Disconnected if reconnect_max_attempts is exhausted.
        await $weak_self->_reconnect;

        # Delegate the replay, on_reconnect, and driver-restart work to
        # the subscription's unified resume path. _resume_after_reconnect
        # handles clearing _paused, setting in_pubsub, replaying all
        # tracked channels/patterns, firing on_reconnect, and starting
        # the driver. Keeps the "who restarts what after reconnect"
        # logic in one place.
        if ($weak_sub) {
            await $weak_sub->_resume_after_reconnect;
        }
    })->();

    # Ownership: the selector owns the task; the slot is the dedup signal.
    # No ->retain — the selector holds the strong reference.
    $self->{_reconnect_future} = $f;
    $self->{_tasks}->add(data => 'pubsub-reconnect', f => $f);

    $f->on_ready(sub {
        return unless $weak_self;
        $weak_self->{_reconnect_future} = undef;
    });
    $f->on_fail(sub {
        my $err = shift;
        return unless $weak_sub;
        $weak_sub->_fail_fatal($err);
    });

    return;
}

# Execute a Redis command
async sub command {
    my ($self, $cmd, @args) = @_;

    # Check for fork - invalidate connection if PID changed
    $self->_check_fork;

    # Block regular commands on pubsub connection
    if ($self->{in_pubsub}) {
        my $ucmd = uc($cmd // '');
        unless ($ucmd =~ /^(SUBSCRIBE|UNSUBSCRIBE|PSUBSCRIBE|PUNSUBSCRIBE|SSUBSCRIBE|SUNSUBSCRIBE|PING|QUIT)$/) {
            die Async::Redis::Error::Protocol->new(
                message => "Cannot execute '$cmd' on connection in PubSub mode",
            );
        }
    }

    # Apply key prefixing if configured
    if (defined $self->{prefix} && $self->{prefix} ne '') {
        @args = Async::Redis::KeyExtractor::apply_prefix(
            $self->{prefix}, $cmd, @args
        );
    }

    # Route through auto-pipeline if enabled
    if ($self->{_auto_pipeline}) {
        return await $self->{_auto_pipeline}->command($cmd, @args);
    }

    # Telemetry: start span and log send
    my $span_context;
    my $start_time = Time::HiRes::time();
    if ($self->{_telemetry}) {
        $span_context = $self->{_telemetry}->start_command_span($cmd, @args);
        $self->{_telemetry}->log_send($cmd, @args);
    }

    my $raw_cmd  = $self->_build_command($cmd, @args);
    my $deadline = $self->_calculate_deadline($cmd, @args);
    my $response = Future->new;

    my $result;
    my $error;

    my $submit_ok = eval {
        await $self->_with_write_gate(sub {
            return (async sub {
                # Ensure the socket is live. Reconnect if enabled, else fail.
                if (!$self->{_socket_live}) {
                    if ($self->_reconnect_enabled) {
                        await $self->_ensure_connected;
                    } else {
                        die Async::Redis::Error::Disconnected->new(
                            message => "Not connected",
                        );
                    }
                }
                # Register inflight BEFORE writing so order matches the wire.
                $self->_add_inflight($response, $cmd, \@args, $deadline, 'fail');
                await $self->_send($raw_cmd);
            })->();
        });
        1;
    };

    if (!$submit_ok) {
        $error = $@;
        # _with_write_gate already called _reader_fatal on write failure.
    } else {
        $self->_ensure_reader;
        # run_until_ready awaits $response while the selector pumps the
        # reader (and any other adopted tasks). If any selector task fails
        # unhandled — in particular, the reader — the failure propagates
        # here, so callers never hang waiting on a dead reader.
        my $await_ok = eval {
            $result = await $self->{_tasks}->run_until_ready($response);
            1;
        };
        if (!$await_ok) { $error = $@ }
    }

    # Telemetry: log result and end span
    if ($self->{_telemetry}) {
        my $elapsed_ms = (Time::HiRes::time() - $start_time) * 1000;
        if ($error) {
            $self->{_telemetry}->log_error($error);
        }
        else {
            $self->{_telemetry}->log_recv($result, $elapsed_ms);
        }
        $self->{_telemetry}->end_command_span($span_context, $error);
    }

    die $error if $error;
    return $result;
}

# Read response with deadline enforcement
async sub _read_response_with_deadline {
    my ($self, $deadline, $cmd_ref) = @_;

    # First check if parser already has a complete message
    if (my $msg = $self->{parser}->get_message) {
        return $msg;
    }

    # Read until we get a complete message
    while (1) {
        my $remaining = $deadline - Time::HiRes::time();

        if ($remaining <= 0) {
            $self->_reset_connection;
            die Async::Redis::Error::Timeout->new(
                message        => "Request timed out after $self->{request_timeout}s",
                command        => $cmd_ref,
                timeout        => $self->{request_timeout},
                maybe_executed => 1,  # already sent the command
            );
        }

        # Use wait_any for timeout
        my $read_f = Future::IO->read($self->{socket}, 65536);

        # Store reference so disconnect() can cancel it
        $self->{_current_read_future} = $read_f;

        my $timeout_f = Future::IO->sleep($remaining)->then(sub {
            return Future->fail('read_timeout');
        });

        my $wait_f = Future->wait_any($read_f, $timeout_f);
        await $wait_f;

        # Clear stored reference after await completes
        $self->{_current_read_future} = undef;

        # Check if read was cancelled (by disconnect)
        if ($read_f->is_cancelled) {
            die Async::Redis::Error::Disconnected->new(
                message => "Disconnected during read",
            );
        }

        if ($wait_f->is_failed) {
            my ($error) = $wait_f->failure;
            if ($error eq 'read_timeout') {
                $self->_reset_connection;
                die Async::Redis::Error::Timeout->new(
                    message        => "Request timed out after $self->{request_timeout}s",
                    command        => $cmd_ref,
                    timeout        => $self->{request_timeout},
                    maybe_executed => 1,
                );
            }
            $self->_reset_connection;
            die Async::Redis::Error::Connection->new(
                message => "$error",
            );
        }

        # Get the read result
        my $buf = $wait_f->get;

        # EOF
        if (!defined $buf || length($buf) == 0) {
            $self->_reset_connection;
            die Async::Redis::Error::Connection->new(
                message => "Connection closed by server",
            );
        }

        $self->{parser}->parse($buf);

        if (my $msg = $self->{parser}->get_message) {
            return $msg;
        }
    }
}

# Reset connection after timeout (stream is desynced)
sub _reset_connection {
    my ($self, $reason) = @_;
    $reason //= 'timeout';

    my $was_connected = $self->{connected};

    # Cancel any active read future BEFORE closing socket
    # This ensures Future::IO unregisters its watcher while fileno is still valid
    if ($self->{_current_read_future} && !$self->{_current_read_future}->is_ready) {
        $self->{_current_read_future}->cancel;
        $self->{_current_read_future} = undef;
    }

    # Cancel any pending inflight operations before closing socket
    if (my $inflight = $self->{inflight}) {
        for my $entry (@$inflight) {
            if ($entry->{future} && !$entry->{future}->is_ready) {
                $entry->{future}->cancel;
            }
        }
        $self->{inflight} = [];
    }

    if ($self->{socket}) {
        $self->_close_socket;
    }

    $self->{_socket_live}       = 0;
    $self->{_fatal_in_progress} = 0;
    $self->{_reader_running}    = 0;
    $self->{_reconnect_future}  = undef;
    $self->{connected}          = 0;
    $self->{parser}             = undef;
    $self->{in_pubsub}          = 0;

    if ($was_connected && $self->{on_disconnect}) {
        $self->{on_disconnect}->($self, $reason);
    }
}

# Async write lock. The lock is a Future that resolves when the current
# holder releases. Waiters chain onto it; each waiter replaces the slot
# with its own Future before returning to the caller.
async sub _acquire_write_lock {
    my ($self) = @_;

    # Wait out any in-progress fatal. _reader_fatal is synchronous so this
    # is typically immediate, but a callback inside fatal could yield.
    # NOTE: this is a poll loop (sleep(0) per tick). Acceptable because
    # _reader_fatal's transition is synchronous; if teardown ever becomes
    # async, replace with a one-shot Future waiters can await on.
    while ($self->{_fatal_in_progress}) {
        await Future::IO->sleep(0);
    }

    # Chain onto the existing lock Future if any.
    while (my $prev = $self->{_write_lock}) {
        await $prev;
    }

    # We are the owner now. Install our own Future so the next caller
    # waits on us.
    $self->{_write_lock} = Future->new;
    return;
}

sub _release_write_lock {
    my ($self) = @_;
    my $f = delete $self->{_write_lock};
    $f->done if $f && !$f->is_ready;
}

# Wrap a body in gate acquire/release with guaranteed release even if the
# body dies. On body failure, calls _reader_fatal with a transport error.
async sub _with_write_gate {
    my ($self, $body) = @_;
    await $self->_acquire_write_lock;
    my $ok = eval { await $body->(); 1 };
    my $err = $@;
    $self->_release_write_lock;
    if (!$ok) {
        # Convert to a typed transport error if not already.
        my $typed = (ref $err && eval { $err->isa('Async::Redis::Error') })
            ? $err
            : Async::Redis::Error::Connection->new(
                message => "Write failed: $err",
                host    => $self->{host},
                port    => $self->{port},
            );
        $self->_reader_fatal($typed);
        die $typed;
    }
    return;
}

# Is reconnect enabled for this client?
sub _reconnect_enabled {
    my ($self) = @_;
    return !!$self->{reconnect};
}

# Central "something went wrong with the stream" transition. Detaches
# inflight BEFORE closing the socket so the typed error is preserved
# (the old _reset_connection cancels inflight directly, which would
# overwrite $typed_error with a generic cancellation).
sub _reader_fatal {
    my ($self, $typed_error) = @_;

    return if $self->{_fatal_in_progress};
    $self->{_fatal_in_progress} = 1;

    my $ok = eval {
        # 1. Capture pre-reset state BEFORE any mutation.
        my $was_connected = $self->{connected};
        my $was_pubsub    = $self->{in_pubsub};
        my $subscription  = $self->{_subscription};

        # 2. Detach inflight so the close path cannot cancel them.
        my $detached_inflight = $self->{inflight};
        $self->{inflight} = [];

        # 3. Detach auto-pipeline's queued-but-not-registered commands.
        my $detached_autopipe = [];
        if (my $ap = $self->{_auto_pipeline}) {
            $detached_autopipe = $ap->_detach_queued;
        }

        # 4. Cancel the current read BEFORE closing the socket.
        if ($self->{_current_read_future}
            && !$self->{_current_read_future}->is_ready) {
            $self->{_current_read_future}->cancel;
        }
        $self->{_current_read_future} = undef;

        # 5. Close socket, clear internal state.
        $self->_close_socket if $self->{socket};
        $self->{_socket_live}   = 0;
        $self->{connected}      = 0;
        $self->{parser}         = undef;
        $self->{in_pubsub}      = 0;
        $self->{_reader_running} = 0;

        # 6. Fail all detached futures with the SAME typed error.
        for my $entry (@$detached_inflight, @$detached_autopipe) {
            next if $entry->{future}->is_ready;
            $entry->{future}->fail($typed_error);
        }

        # 7. Pubsub reconnect handoff. _fail_fatal and _pause_for_reconnect
        #    land in Phase 2 (Task 14); for now this branch only triggers
        #    when the subscription API is used, and we call the older
        #    _close path as a placeholder until Task 14 replaces it.
        if ($was_pubsub && $subscription) {
            if ($self->_reconnect_enabled
                && $subscription->can('_pause_for_reconnect')) {
                $subscription->_pause_for_reconnect;
                if ($self->can('_reconnect_async')) {
                    $self->_reconnect_async($subscription);
                }
            }
            elsif ($subscription->can('_fail_fatal')) {
                $subscription->_fail_fatal($typed_error);
            }
            else {
                # Pre-Phase-2 fallback: existing _close method.
                $subscription->_close if $subscription->can('_close');
            }
        }

        # 8. on_disconnect: only if we were publicly connected.
        if ($was_connected && $self->{on_disconnect}) {
            $self->{on_disconnect}->($self, "$typed_error");
        }

        1;
    };

    my $caught = $@;
    # Always clear the guard, even if a callback died.
    $self->{_fatal_in_progress} = 0;
    die $caught if !$ok && $caught;
}

# Decode Protocol::Redis response to Perl value
sub _decode_response {
    my ($self, $msg) = @_;

    return undef unless $msg;

    my $type = $msg->{type};
    my $data = $msg->{data};

    # Simple string (+)
    if ($type eq '+') {
        return $data;
    }
    # Error (-)
    elsif ($type eq '-') {
        die Async::Redis::Error::Redis->from_message($data);
    }
    # Integer (:)
    elsif ($type eq ':') {
        return 0 + $data;
    }
    # Bulk string ($)
    elsif ($type eq '$') {
        return $data;  # undef for null bulk
    }
    # Array (*)
    elsif ($type eq '*') {
        return undef unless defined $data;  # null array
        return [ map { $self->_decode_response($_) } @$data ];
    }

    return $data;
}

# Non-throwing decoder used by the unified reader. Classifies each frame
# as one of:
#   ('ok',             $decoded_value)      - normal response
#   ('redis_error',    $error_object)       - -ERR frame from Redis
#   ('protocol_error', $error_object)       - fatal desync (malformed)
sub _decode_response_result {
    my ($self, $msg) = @_;

    if (!defined $msg) {
        return ('protocol_error', Async::Redis::Error::Protocol->new(
            message => 'undef message from parser',
        ));
    }

    my $type = $msg->{type} // '';
    my $data = $msg->{data};

    if ($type eq '+') {
        return ('ok', $data);
    }
    elsif ($type eq '-') {
        return ('redis_error', Async::Redis::Error::Redis->from_message($data));
    }
    elsif ($type eq ':') {
        return ('ok', 0 + ($data // 0));
    }
    elsif ($type eq '$') {
        return ('ok', $data);
    }
    elsif ($type eq '*') {
        return ('ok', undef) if !defined $data;   # nil array
        my @out;
        for my $child (@$data) {
            my ($k, $v) = $self->_decode_response_result($child);
            if ($k eq 'protocol_error') {
                return ($k, $v);   # propagate fatal
            }
            push @out, $v;
        }
        return ('ok', \@out);
    }
    else {
        return ('protocol_error', Async::Redis::Error::Protocol->new(
            message => "unknown frame type: $type",
        ));
    }
}

# ============================================================================
# Convenience Commands
# ============================================================================

async sub ping {
    my ($self) = @_;
    return await $self->command('PING');
}

async sub set {
    my ($self, $key, $value, %opts) = @_;
    my @cmd = ('SET', $key, $value);
    push @cmd, 'EX', $opts{ex} if exists $opts{ex};
    push @cmd, 'PX', $opts{px} if exists $opts{px};
    push @cmd, 'NX' if $opts{nx};
    push @cmd, 'XX' if $opts{xx};
    return await $self->command(@cmd);
}

async sub get {
    my ($self, $key) = @_;
    return await $self->command('GET', $key);
}

async sub del {
    my ($self, @keys) = @_;
    return await $self->command('DEL', @keys);
}

async sub incr {
    my ($self, $key) = @_;
    return await $self->command('INCR', $key);
}

async sub lpush {
    my ($self, $key, @values) = @_;
    return await $self->command('LPUSH', $key, @values);
}

async sub rpush {
    my ($self, $key, @values) = @_;
    return await $self->command('RPUSH', $key, @values);
}

async sub lpop {
    my ($self, $key) = @_;
    return await $self->command('LPOP', $key);
}

async sub lrange {
    my ($self, $key, $start, $stop) = @_;
    return await $self->command('LRANGE', $key, $start, $stop);
}

async sub keys {
    my ($self, $pattern) = @_;
    return await $self->command('KEYS', $pattern // '*');
}

async sub flushdb {
    my ($self) = @_;
    return await $self->command('FLUSHDB');
}

# ============================================================================
# Lua Scripting
# ============================================================================

async sub script_load {
    my ($self, $script) = @_;
    return await $self->command('SCRIPT', 'LOAD', $script);
}

async sub script_exists {
    my ($self, @shas) = @_;
    return await $self->command('SCRIPT', 'EXISTS', @shas);
}

async sub script_flush {
    my ($self, $mode) = @_;
    my @args = ('SCRIPT', 'FLUSH');
    push @args, $mode if $mode;  # ASYNC or SYNC
    return await $self->command(@args);
}

async sub script_kill {
    my ($self) = @_;
    return await $self->command('SCRIPT', 'KILL');
}

async sub evalsha_or_eval {
    my ($self, $sha, $script, $numkeys, @keys_and_args) = @_;

    # Try EVALSHA first
    my $result;
    eval {
        $result = await $self->evalsha($sha, $numkeys, @keys_and_args);
    };

    if ($@) {
        my $error = $@;

        # Check if it's a NOSCRIPT error
        if ("$error" =~ /NOSCRIPT/i) {
            # Fall back to EVAL (which also loads the script)
            $result = await $self->eval($script, $numkeys, @keys_and_args);
        }
        else {
            # Re-throw other errors
            die $error;
        }
    }

    return $result;
}

sub script {
    my ($self, $code) = @_;
    return Async::Redis::Script->new(
        redis  => $self,
        script => $code,
    );
}

# Define a named script command
# Usage: $redis->define_command(name => { keys => N, lua => '...' })
sub define_command {
    my ($self, $name, $def) = @_;

    die "Command name required" unless defined $name && length $name;
    die "Command definition required" unless ref $def eq 'HASH';
    die "Lua script required (lua => '...')" unless defined $def->{lua};
    die "define_command install option is not supported; use run_script()"
        if exists $def->{install};

    # Validate name (alphanumeric and underscore only)
    die "Invalid command name '$name' - use only alphanumeric and underscore"
        unless $name =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;

    my $script = Async::Redis::Script->new(
        redis       => $self,
        script      => $def->{lua},
        name        => $name,
        num_keys    => $def->{keys} // 'dynamic',
        description => $def->{description},
    );

    $self->{_scripts}{$name} = $script;

    return $script;
}

# Run a registered script by name
# Usage: $redis->run_script('name', @keys_then_args)
# If num_keys is 'dynamic', first arg is the key count
async sub run_script {
    my ($self, $name, @args) = @_;

    my $script = $self->{_scripts}{$name}
        or die "Unknown script: '$name' - use define_command() first";

    my $num_keys = $script->num_keys;

    # Handle dynamic key count
    if ($num_keys eq 'dynamic') {
        $num_keys = shift @args;
        die "Key count required as first argument for dynamic script '$name'"
            unless defined $num_keys;
    }

    # Split args into keys and argv
    my @keys = splice(@args, 0, $num_keys);
    return await $script->run(\@keys, \@args);
}

# Get a registered script by name
sub get_script {
    my ($self, $name) = @_;
    return $self->{_scripts}{$name};
}

# List all registered script names
sub list_scripts {
    my ($self) = @_;
    return CORE::keys %{$self->{_scripts}};
}

# Preload all registered scripts to Redis
# Useful before pipeline execution
async sub preload_scripts {
    my ($self) = @_;

    my @names = $self->list_scripts;
    return 0 unless @names;

    for my $name (@names) {
        my $script = $self->{_scripts}{$name};
        await $self->script_load($script->script);
    }

    return scalar @names;
}

# ============================================================================
# SCAN Iterators
# ============================================================================

sub scan_iter {
    my ($self, %opts) = @_;
    return Async::Redis::Iterator->new(
        redis   => $self,
        command => 'SCAN',
        match   => $opts{match},
        count   => $opts{count},
        type    => $opts{type},
    );
}

sub hscan_iter {
    my ($self, $key, %opts) = @_;
    return Async::Redis::Iterator->new(
        redis   => $self,
        command => 'HSCAN',
        key     => $key,
        match   => $opts{match},
        count   => $opts{count},
    );
}

sub sscan_iter {
    my ($self, $key, %opts) = @_;
    return Async::Redis::Iterator->new(
        redis   => $self,
        command => 'SSCAN',
        key     => $key,
        match   => $opts{match},
        count   => $opts{count},
    );
}

sub zscan_iter {
    my ($self, $key, %opts) = @_;
    return Async::Redis::Iterator->new(
        redis   => $self,
        command => 'ZSCAN',
        key     => $key,
        match   => $opts{match},
        count   => $opts{count},
    );
}

# ============================================================================
# Transactions
# ============================================================================

async sub multi {
    my ($self, $callback) = @_;

    # Prevent nested multi() calls
    die "Cannot nest multi() calls - already in a transaction"
        if $self->{in_multi};

    # Mark that we're collecting transaction commands
    $self->{in_multi} = 1;

    my @commands;
    eval {
        # Create transaction collector
        my $tx = Async::Redis::Transaction->new(redis => $self);

        # Run callback to collect commands
        await $callback->($tx);

        @commands = $tx->commands;
    };
    my $collect_error = $@;

    if ($collect_error) {
        $self->{in_multi} = 0;
        die $collect_error;
    }

    # If no commands queued, return empty result
    unless (@commands) {
        $self->{in_multi} = 0;
        return [];
    }

    # Execute transaction (in_multi already set)
    return await $self->_execute_transaction(\@commands);
}

async sub _execute_transaction {
    my ($self, $commands) = @_;

    # in_multi should already be set by caller

    my $results;
    eval {
        # Send MULTI
        await $self->command('MULTI');

        # Queue all commands (they return +QUEUED)
        for my $cmd (@$commands) {
            await $self->command(@$cmd);
        }

        # Execute and get results
        $results = await $self->command('EXEC');
    };
    my $error = $@;

    # Always clear transaction state
    $self->{in_multi} = 0;

    if ($error) {
        # Try to clean up
        eval { await $self->command('DISCARD') };
        die $error;
    }

    return $results;
}

# Accessor for pool cleanliness tracking
sub in_multi { shift->{in_multi} }
sub watching { shift->{watching} }
sub in_pubsub { shift->{in_pubsub} }
sub inflight_count { scalar @{shift->{inflight} // []} }

# Is connection dirty (unsafe to reuse)?
sub is_dirty {
    my ($self) = @_;

    return 1 if $self->{in_multi};
    return 1 if $self->{watching};
    return 1 if $self->{in_pubsub};
    return 1 if @{$self->{inflight} // []} > 0;

    return 0;
}

async sub watch {
    my ($self, @keys) = @_;
    my $result = await $self->command('WATCH', @keys);
    $self->{watching} = 1;
    return $result;
}

async sub unwatch {
    my ($self) = @_;
    my $result = await $self->command('UNWATCH');
    $self->{watching} = 0;
    return $result;
}

async sub multi_start {
    my ($self) = @_;
    my $result = await $self->command('MULTI');
    $self->{in_multi} = 1;
    return $result;
}

async sub exec {
    my ($self) = @_;
    my $result = await $self->command('EXEC');
    $self->{in_multi} = 0;
    $self->{watching} = 0;  # EXEC clears watches
    return $result;
}

async sub discard {
    my ($self) = @_;
    my $result = await $self->command('DISCARD');
    $self->{in_multi} = 0;
    $self->{watching} = 0;  # DISCARD clears watches
    return $result;
}

async sub watch_multi {
    my ($self, $keys, $callback) = @_;

    my $watch_active  = 0;
    my $multi_started = 0;
    my $results;

    my $ok = eval {
        # WATCH must be unwound on any pre-MULTI failure, including a
        # callback die, otherwise the connection remains poisoned.
        await $self->watch(@$keys);
        $watch_active = 1;

        # Get current values of watched keys
        my %watched;
        for my $key (@$keys) {
            $watched{$key} = await $self->get($key);
        }

        # Create transaction collector
        my $tx = Async::Redis::Transaction->new(redis => $self);

        # Run callback with watched values
        await $callback->($tx, \%watched);

        my @commands = $tx->commands;

        # If no commands queued, just unwatch and return empty
        unless (@commands) {
            await $self->unwatch;
            $watch_active = 0;
            $results = [];
        }
        else {
            await $self->multi_start;
            $multi_started = 1;

            for my $cmd (@commands) {
                await $self->command(@$cmd);
            }

            $results = await $self->exec;
            $multi_started = 0;
            $watch_active  = 0;
        }

        1;
    };
    my $error = $@;

    if (!$ok) {
        if ($multi_started) {
            eval { await $self->discard; 1 };
        }
        elsif ($watch_active) {
            eval { await $self->unwatch; 1 };
        }

        # Cleanup can fail on a dead socket; keep local state conservative
        # and preserve the original caller-facing error.
        $self->{in_multi} = 0;
        $self->{watching} = 0;

        die $error;
    }

    # EXEC returns undef/nil if WATCH failed
    return $results;
}

# ============================================================================
# PUB/SUB
# ============================================================================

# Wait for inflight commands to complete before mode change
async sub _wait_for_inflight_drain {
    my ($self, $timeout) = @_;
    $timeout //= 30;

    return unless @{$self->{inflight}};

    my $deadline = Time::HiRes::time() + $timeout;

    while (@{$self->{inflight}} && Time::HiRes::time() < $deadline) {
        await Future::IO->sleep(0.001);
    }

    if (@{$self->{inflight}}) {
        $self->_fail_all_inflight("Timeout waiting for inflight commands");
    }
}

async sub publish {
    my ($self, $channel, $message) = @_;
    return await $self->command('PUBLISH', $channel, $message);
}

async sub spublish {
    my ($self, $channel, $message) = @_;
    return await $self->command('SPUBLISH', $channel, $message);
}

# Subscribe to channels - returns a Subscription object
async sub subscribe {
    my ($self, @channels) = @_;

    die Async::Redis::Error::Disconnected->new(
        message => "Not connected",
    ) unless $self->{connected};

    # Wait for pending commands before entering PubSub mode
    await $self->_wait_for_inflight_drain;

    # Clear a stale closed subscription so we allocate a fresh object.
    if ($self->{_subscription} && $self->{_subscription}->is_closed) {
        delete $self->{_subscription};
    }

    # Create or reuse subscription
    my $sub = $self->{_subscription} //= Async::Redis::Subscription->new(redis => $self);

    # Set in_pubsub BEFORE submitting so the unified reader classifies
    # racing message frames correctly (e.g. published before our
    # confirmation arrives).
    $self->{in_pubsub} = 1;

    # Issue one SUBSCRIBE per channel through the write gate and unified
    # reader. Each call awaits its matching confirmation frame.
    for my $ch (@channels) {
        await $self->_pubsub_command('SUBSCRIBE', $ch);
        $sub->_add_channel($ch);
    }

    return $sub;
}

# Pattern subscribe
async sub psubscribe {
    my ($self, @patterns) = @_;

    die Async::Redis::Error::Disconnected->new(
        message => "Not connected",
    ) unless $self->{connected};

    # Wait for pending commands before entering PubSub mode
    await $self->_wait_for_inflight_drain;

    # Clear a stale closed subscription so we allocate a fresh object.
    if ($self->{_subscription} && $self->{_subscription}->is_closed) {
        delete $self->{_subscription};
    }

    my $sub = $self->{_subscription} //= Async::Redis::Subscription->new(redis => $self);

    $self->{in_pubsub} = 1;

    for my $p (@patterns) {
        await $self->_pubsub_command('PSUBSCRIBE', $p);
        $sub->_add_pattern($p);
    }

    return $sub;
}

# Sharded subscribe (Redis 7+)
async sub ssubscribe {
    my ($self, @channels) = @_;

    die Async::Redis::Error::Disconnected->new(
        message => "Not connected",
    ) unless $self->{connected};

    # Wait for pending commands before entering PubSub mode
    await $self->_wait_for_inflight_drain;

    # Clear a stale closed subscription so we allocate a fresh object.
    if ($self->{_subscription} && $self->{_subscription}->is_closed) {
        delete $self->{_subscription};
    }

    my $sub = $self->{_subscription} //= Async::Redis::Subscription->new(redis => $self);

    $self->{in_pubsub} = 1;

    for my $ch (@channels) {
        await $self->_pubsub_command('SSUBSCRIBE', $ch);
        $sub->_add_sharded_channel($ch);
    }

    return $sub;
}

# Read pubsub frame (subscription confirmation or message)
async sub _read_pubsub_frame {
    my ($self) = @_;

    die Async::Redis::Error::Disconnected->new(
        message => "Not connected",
    ) unless $self->{connected};

    my $msg = await $self->_read_response();
    return $self->_decode_response($msg);
}

# Execute a single pubsub management command (SUBSCRIBE, UNSUBSCRIBE,
# PSUBSCRIBE, PUNSUBSCRIBE, SSUBSCRIBE, SUNSUBSCRIBE) through the write
# gate and unified reader. Each call registers one inflight entry and
# awaits the matching confirmation frame from the reader.
#
# Use instead of _send_command + _read_pubsub_frame when in_pubsub=1
# so that the unified reader (_run_reader) remains the sole socket
# reader. Does not apply prefix or go through auto-pipeline.
async sub _pubsub_command {
    my ($self, $cmd, @args) = @_;

    my $raw_cmd  = $self->_build_command($cmd, @args);
    my $deadline = $self->_calculate_deadline($cmd, @args);
    my $response = Future->new;

    my $submit_ok = eval {
        await $self->_with_write_gate(sub {
            return (async sub {
                if (!$self->{_socket_live}) {
                    die Async::Redis::Error::Disconnected->new(
                        message => "Not connected",
                    );
                }
                # Register inflight BEFORE writing so order matches the wire.
                $self->_add_inflight($response, $cmd, \@args, $deadline, 'fail');
                await $self->_send($raw_cmd);
            })->();
        });
        1;
    };

    unless ($submit_ok) {
        my $err = $@;
        die $err;
    }

    $self->_ensure_reader;
    return await $response;
}

# Send command without reading response (for pubsub)
async sub _send_command {
    my ($self, @args) = @_;

    my $cmd = $self->_build_command(@args);
    await $self->_send($cmd);
}

# Read next pubsub message (blocking) - for compatibility
async sub _read_pubsub_message {
    my ($self) = @_;

    my $msg = await $self->_read_response();

    # Message format: ['message', $channel, $payload]
    # or: ['pmessage', $pattern, $channel, $payload]
    return $msg;
}

# ============================================================================
# Pipelining
# ============================================================================

sub pipeline {
    my ($self, %opts) = @_;
    return Async::Redis::Pipeline->new(
        redis     => $self,
        max_depth => $opts{max_depth} // $self->{pipeline_depth},
    );
}

# Execute multiple commands, return all responses
async sub _execute_pipeline {
    my ($self, $commands) = @_;
    return [] unless @$commands;

    my $start_time = Time::HiRes::time();
    my $count      = scalar @$commands;

    # Build one RESP buffer and one Future per command up front.
    my $buffer = '';
    my @futures;
    my @deadlines;
    for my $cmd (@$commands) {
        $buffer .= $self->_build_command(@$cmd);
        push @futures, Future->new;
        push @deadlines, $self->_calculate_deadline(@$cmd);
    }

    await $self->_with_write_gate(sub {
        return (async sub {
            if (!$self->{_socket_live}) {
                if ($self->_reconnect_enabled) {
                    await $self->_ensure_connected;
                } else {
                    die Async::Redis::Error::Disconnected->new(
                        message => "Not connected",
                    );
                }
            }
            for my $i (0 .. $#$commands) {
                $self->_add_inflight(
                    $futures[$i],
                    $commands->[$i][0],
                    [ @{$commands->[$i]}[1..$#{$commands->[$i]}] ],
                    $deadlines[$i],
                    'capture',
                );
            }
            await $self->_send($buffer);
        })->();
    });

    $self->_ensure_reader;

    # Await every future. capture policy means Redis errors come back as
    # done($error_object); transport failures come back as fail().
    my @results;
    for my $i (0 .. $#futures) {
        my $ok = eval { push @results, await $futures[$i]; 1 };
        next if $ok;
        # Transport failure mid-pipeline: the remaining futures already
        # got _reader_fatal's typed error. Collect them too (as error
        # values) so the caller sees a full array.
        push @results, $@;
        for my $j ($i + 1 .. $#futures) {
            my $r_ok = eval { push @results, await $futures[$j]; 1 };
            push @results, $@ unless $r_ok;
        }
        last;
    }

    if ($self->{_telemetry}) {
        my $elapsed_ms = (Time::HiRes::time() - $start_time) * 1000;
        $self->{_telemetry}->record_pipeline($count, $elapsed_ms);
    }

    return \@results;
}

1;

__END__

=head1 NAME

Async::Redis - Async Redis client using Future::IO

=head1 SYNOPSIS

    use Async::Redis;
    use Future::AsyncAwait;

    # Future::IO 0.23+ has a built-in poll-based impl that works
    # out of the box. For IO::Async or UV, require the impl directly:
    # require Future::IO::Impl::IOAsync;  # if using IO::Async
    # require Future::IO::Impl::UV;       # if using UV

    my $redis = Async::Redis->new(
        host => 'localhost',
        port => 6379,
    );

    (async sub {
        await $redis->connect;

        # Simple commands
        await $redis->set('key', 'value');
        my $value = await $redis->get('key');

        # Pipelining for efficiency
        my $pipeline = $redis->pipeline;
        $pipeline->set('k1', 'v1');
        $pipeline->set('k2', 'v2');
        $pipeline->get('k1');
        my $results = await $pipeline->execute;

        # PubSub
        my $sub = await $redis->subscribe('channel');
        while (my $msg = await $sub->next_message) {
            print "Received: $msg->{message}\n";
        }
    })->()->await;

B<Important:> If you're embedding Async::Redis in a larger application
(web framework, existing event loop, etc.), see L</EVENT LOOP CONFIGURATION>
for how to properly configure Future::IO. Libraries should never configure
the Future::IO backend - only your application's entry point should.

=head1 DESCRIPTION

Async::Redis is an asynchronous Redis client built on L<Future::IO>,
providing a modern, non-blocking interface for Redis operations.

Key features:

=over 4

=item * Full async/await support via L<Future::AsyncAwait>

=item * Event loop agnostic (IO::Async, AnyEvent, UV, etc.)

=item * Automatic reconnection with exponential backoff

=item * Connection pooling with health checks

=item * Pipelining and auto-pipelining

=item * PubSub with automatic subscription replay on reconnect

When a connection drops during pub/sub mode and C<reconnect> is enabled,
all subscriptions are automatically re-established. Use
C<< $subscription->on_reconnect(sub { ... }) >> to be notified when this
happens (e.g., to re-poll state that may have changed during the outage).

=item * Transaction support (MULTI/EXEC/WATCH)

=item * TLS/SSL connections

=item * OpenTelemetry observability integration

=item * Fork-safe for pre-fork servers (Starman, etc.)

=item * Full RESP2 protocol support

=item * Safe concurrent commands on single connection

=back

=head1 CONCURRENT COMMANDS

Async::Redis safely handles multiple concurrent commands on a single
connection using a response queue pattern. When you fire multiple async
commands without explicitly awaiting them:

    my @futures = (
        $redis->set('k1', 'v1'),
        $redis->set('k2', 'v2'),
        $redis->get('k1'),
    );
    my @results = await Future->needs_all(@futures);

Each command is registered in an inflight queue before being sent to Redis.
A single reader coroutine processes responses in FIFO order, matching each
response to the correct waiting future. This prevents response mismatch bugs
that can occur when multiple coroutines race to read from the socket.

For high-throughput scenarios, consider using:

=over 4

=item * B<Explicit pipelines> - C<< $redis->pipeline >> batches commands
for a single network round-trip

=item * B<Auto-pipeline> - C<< auto_pipeline => 1 >> automatically batches
commands within an event loop tick

=item * B<Connection pools> - L<Async::Redis::Pool> for parallel execution
across multiple connections

=back

=head1 CONSTRUCTOR

=head2 new

    my $redis = Async::Redis->new(%options);

Creates a new Redis client instance. Does not connect immediately.

Options:

=over 4

=item host => $hostname

Redis server hostname. Default: 'localhost'

=item port => $port

Redis server port. Default: 6379

=item uri => $uri

Connection URI (e.g., 'redis://user:pass@host:port/db').
If provided, overrides host, port, password, database options.

=item path => $path

Unix domain socket path. When provided, C<host> and C<port> are ignored.
Also available via C<redis+unix://> URIs.

=item password => $password

Authentication password.

=item username => $username

Authentication username (Redis 6+ ACL).

=item database => $db

Database number to SELECT after connect. Default: 0

=item tls => $bool | \%options

Enable TLS/SSL connection. Can be a boolean or hashref with options:

    tls => {
        ca_file   => '/path/to/ca.crt',
        cert_file => '/path/to/client.crt',
        key_file  => '/path/to/client.key',
        verify    => 1,  # verify server certificate
        verify_hostname => 1,  # verify certificate name/IP
    }

=item connect_timeout => $seconds

Connection timeout. Default: 10

=item request_timeout => $seconds

Per-request timeout for commands. Default: 5

Blocking commands (BLPOP, BRPOP, etc.) automatically extend this timeout
based on their server-side timeout plus C<blocking_timeout_buffer>.
Blocking commands with a Redis timeout of C<0> block indefinitely and do not
get a client-side request deadline.

=item blocking_timeout_buffer => $seconds

Extra time added to blocking command timeouts. Default: 2

For example, C<BLPOP key 30> gets a deadline of 30 + 2 = 32 seconds.

=item reconnect => $bool

Enable automatic reconnection. Default: 0

=item reconnect_delay => $seconds

Initial reconnect delay. Default: 0.1

=item reconnect_delay_max => $seconds

Maximum reconnect delay. Default: 60

=item reconnect_jitter => $ratio

Jitter ratio for reconnect delays. Default: 0.25

=item reconnect_max_attempts => $int

Maximum number of reconnect attempts before C<_reconnect> gives up
and dies with an L<Async::Redis::Error::Disconnected>. Default: 10.
Set to C<0> for unlimited retries (not recommended in production:
an unreachable Redis will loop with exponential backoff forever,
giving consumers no way to distinguish "reconnecting" from "broken").

When the cap is exceeded, the failure propagates through
C<_reconnect_pubsub> to any active L<Async::Redis::Subscription>'s
read loop, where it routes to C<on_error> (or C<die>s loudly if
no C<on_error> is registered) per the existing Subscription
fatal-error contract.

=item on_connect => $coderef

Callback when connection is established. Called as C<< $coderef->($redis) >>.

=item on_disconnect => $coderef

Callback when a live connection is intentionally closed or lost. Called as
C<< $coderef->($redis, $reason) >>.

=item on_error => $coderef

Callback for connection/read errors before they are propagated. Called as
C<< $coderef->($redis, $error) >>.

=item prefix => $prefix

Key prefix applied to supported key-bearing commands. See
L</PREFIX LIMITATIONS>.

=item client_name => $name

CLIENT SETNAME value sent on connect.

=item pipeline_depth => $int

Maximum commands allowed in an explicit pipeline. Default: 10000

=item auto_pipeline => $bool

If true, commands issued in the same event-loop tick are automatically batched
and sent as one pipeline. Default: 0

=item message_queue_depth => $int

Maximum number of locally queued pub/sub messages before the reader applies
backpressure. Must be at least 1. Default: 1

=item debug => $bool | $coderef

Enable debug logging. A true non-coderef logs to STDERR. A coderef receives
C<< ($direction, $data) >>.

=item otel_tracer => $tracer

OpenTelemetry tracer for span creation.

=item otel_meter => $meter

OpenTelemetry meter for metrics.

=item otel_include_args => $bool

Include command arguments in OpenTelemetry span statements. Default: 0.
See L</OPENTELEMETRY ARGUMENTS>.

=item otel_redact => $bool

Apply built-in credential redaction when command arguments are included in
logs or spans. Default: 1.

=back

=head2 PREFIX LIMITATIONS

The C<prefix> option is a convenience for namespacing keys; it is not a hard
security boundary. Key extraction is driven by a hand-maintained map
covering common Redis commands. As of 0.002000, the following commands have
incomplete or missing key extraction: BITFIELD, LMPOP, BLMPOP, ZINTERCARD,
LCS, GEORADIUS_RO, GEORADIUSBYMEMBER_RO. Calls to these commands will not
have prefixes applied. For multi-tenant isolation, use Redis ACLs or
separate Redis databases rather than relying on C<prefix>.

=head2 TLS HOSTNAME VERIFICATION

Starting in 0.002000, TLS connections verify the server certificate's
hostname (or IP SAN) by default when C<verify> is on. If you connect by
hostname, the certificate must have a matching CN or SAN. If you connect by
IP literal, the certificate must have a matching IP SAN.

For deployments where the certificate does not match the connected
hostname/IP (common when connecting to internal IPs with hostname-only
certs), set C<< tls => { verify_hostname => 0 } >> to skip hostname
identity while still verifying the CA chain.

=head1 METHODS

=head2 connect

    await $redis->connect;

Establish connection to Redis server. Returns a Future that resolves
to the Redis client instance.

=head2 disconnect

    $redis->disconnect;

Close connection gracefully.

=head2 is_connected

    my $ok = $redis->is_connected;

Return true when the client currently has an open Redis connection.

=head2 ping

    my $pong = await $redis->ping;

Send C<PING> and return Redis's response.

=head2 command

    my $result = await $redis->command('GET', 'key');

Execute arbitrary Redis command.

=head2 Redis Commands

All standard Redis commands are available as methods. See
L<https://redis.io/docs/latest/commands/> for the complete Redis command
reference.

    # Strings
    await $redis->set('key', 'value');
    await $redis->set('key', 'value', ex => 300);  # with 5min expiry
    await $redis->set('key', 'value', nx => 1);    # only if not exists
    my $value = await $redis->get('key');
    await $redis->incr('counter');
    await $redis->incrby('counter', 5);
    await $redis->mset('k1', 'v1', 'k2', 'v2');
    my $values = await $redis->mget('k1', 'k2');
    await $redis->append('key', ' more');
    await $redis->setex('key', 60, 'value');       # set with 60s expiry

    # Hashes
    await $redis->hset('user:1', 'name', 'Alice', 'email', 'alice@example.com');
    my $name = await $redis->hget('user:1', 'name');
    my $user = await $redis->hgetall('user:1');    # returns hashref
    await $redis->hincrby('user:1', 'visits', 1);
    my $exists = await $redis->hexists('user:1', 'name');
    await $redis->hdel('user:1', 'email');

    # Lists
    await $redis->lpush('queue', 'job1', 'job2');
    await $redis->rpush('queue', 'job3');
    my $left = await $redis->lpop('queue');
    my $right = await $redis->rpop('queue');
    my $popped = await $redis->blpop('queue', 5);  # ['queue', 'job'] or undef
    my $items = await $redis->lrange('queue', 0, -1);
    my $len = await $redis->llen('queue');

    # Sets
    await $redis->sadd('tags', 'perl', 'redis', 'async');
    await $redis->srem('tags', 'async');
    my $members = await $redis->smembers('tags');
    my $is_member = await $redis->sismember('tags', 'perl');
    my $common = await $redis->sinter('tags1', 'tags2');

    # Sorted Sets
    await $redis->zadd('leaderboard', 100, 'alice', 85, 'bob');
    await $redis->zincrby('leaderboard', 10, 'alice');
    my $top = await $redis->zrange('leaderboard', 0, 9, 'WITHSCORES');
    my $rank = await $redis->zrank('leaderboard', 'alice');
    my $score = await $redis->zscore('leaderboard', 'alice');

    # Keys
    my $exists = await $redis->exists('key');
    await $redis->expire('key', 300);
    my $ttl = await $redis->ttl('key');
    await $redis->del('key1', 'key2');
    await $redis->rename('old', 'new');
    my $type = await $redis->type('key');
    my $keys = await $redis->keys('user:*');       # use SCAN in production

=head2 pipeline

    my $pipeline = $redis->pipeline;
    $pipeline->set('k1', 'v1');
    $pipeline->incr('counter');
    my $results = await $pipeline->execute;

Create a pipeline for batched command execution. All commands are
sent in a single network round-trip.

=head2 subscribe

    my $sub = await $redis->subscribe('channel1', 'channel2');

Subscribe to channels. Returns a L<Async::Redis::Subscription> object.

=head2 psubscribe

    my $sub = await $redis->psubscribe('chan:*');

Subscribe to patterns. Returns a L<Async::Redis::Subscription> object.

=head2 ssubscribe

    my $sub = await $redis->ssubscribe('shard-channel');

Subscribe to Redis 7 sharded pub/sub channels. Returns a
L<Async::Redis::Subscription> object.

=head2 publish

    my $receivers = await $redis->publish('channel', 'message');

Publish a regular pub/sub message.

=head2 spublish

    my $receivers = await $redis->spublish('shard-channel', 'message');

Publish a Redis 7 sharded pub/sub message.

=head2 multi

    my $results = await $redis->multi(async sub {
        my ($tx) = @_;
        $tx->set('k1', 'v1');
        $tx->incr('counter');
    });

Execute a transaction with callback.

=head2 watch

    await $redis->watch('key1', 'key2');

Watch keys for a manual optimistic transaction. Redis clears watched keys on
C<EXEC>, C<DISCARD>, or C<UNWATCH>.

=head2 unwatch

    await $redis->unwatch;

Clear all watched keys on the current connection.

=head2 multi_start

    await $redis->multi_start;

Start a manual C<MULTI> transaction and mark the connection dirty until
C<exec> or C<discard>.

=head2 exec

    my $results = await $redis->exec;

Execute a manual transaction. Returns C<undef> if Redis aborts because a
watched key changed.

=head2 discard

    await $redis->discard;

Abort a manual transaction. Redis also clears any active watched keys.

=head2 watch_multi

    my $results = await $redis->watch_multi(['key'], async sub {
        my ($tx, $values) = @_;
        $tx->set('key', $values->{key} + 1);
    });

Watch keys and execute transaction atomically. Returns undef if
watched keys were modified by another client.

=head2 script

    my $script = $redis->script('return redis.call("get", KEYS[1])');
    my $result = await $script->run(['mykey']);

Create a Lua script object with automatic EVALSHA optimization.
See L<Async::Redis::Script> for details.

=head2 define_command

    $redis->define_command(my_command => {
        keys        => 1,               # Number of KEYS (or 'dynamic')
        lua         => 'return ...',    # Lua script code
        description => 'Does X',        # Optional documentation
    });

Register a named Lua script for reuse. The script is automatically cached
and uses EVALSHA for efficiency. Script names are kept in this Redis object's
registry only; they are not installed as Perl methods. Execute registered
scripts with C<run_script>.

Options:

=over 4

=item * C<keys> - Number of KEYS the script expects. Use C<'dynamic'> if
variable (first arg to run_script will be the key count).

=item * C<lua> - The Lua script source code.

=item * C<description> - Optional description for documentation.

=back

=head2 run_script

    my $result = await $redis->run_script('my_command', @keys, @args);

Execute a registered script by name. For scripts with fixed key count,
pass keys then args. For dynamic scripts, pass key count first:

    # Fixed keys (keys => 2)
    await $redis->run_script('two_key_script', 'key1', 'key2', 'arg1');

    # Dynamic keys
    await $redis->run_script('dynamic_script', 2, 'key1', 'key2', 'arg1');

=head2 get_script

    my $script = $redis->get_script('my_command');

Get a registered script object by name. Returns undef if not found.

=head2 list_scripts

    my @names = $redis->list_scripts;

List all registered script names.

=head2 preload_scripts

    my $count = await $redis->preload_scripts;

Load all registered scripts to Redis server. Useful before pipeline
execution to ensure EVALSHA will succeed.

=head2 script_load / script_exists / script_flush / script_kill

    my $sha = await $redis->script_load($lua);
    my $flags = await $redis->script_exists($sha1, $sha2);
    await $redis->script_flush('ASYNC');
    await $redis->script_kill;

Thin wrappers around Redis C<SCRIPT> subcommands.

=head2 is_dirty

    my $dirty = $redis->is_dirty;

Return true if the connection has state that makes it unsafe to return to a
pool: active transaction, watched keys, pub/sub mode, or pending responses.

=head2 in_multi / watching / in_pubsub / inflight_count

State accessors used by L<Async::Redis::Pool> and useful for diagnostics.

=head1 LUA SCRIPTING

Async::Redis provides comprehensive support for Redis Lua scripting with
automatic EVALSHA optimization.

=head2 Quick Start

    # Define a reusable script
    $redis->define_command(atomic_incr => {
        keys => 1,
        lua  => <<'LUA',
            local current = tonumber(redis.call('GET', KEYS[1]) or 0)
            local result = current + tonumber(ARGV[1])
            redis.call('SET', KEYS[1], result)
            return result
LUA
    });

    # Use it
    my $result = await $redis->run_script('atomic_incr', 'counter', 5);

=head2 Pipeline Integration

Registered scripts work in pipelines:

    my $pipe = $redis->pipeline;
    $pipe->run_script('atomic_incr', 'counter:a', 1);
    $pipe->run_script('atomic_incr', 'counter:b', 1);
    $pipe->set('other:key', 'value');
    my $results = await $pipe->execute;

Scripts are automatically preloaded before pipeline execution.

=head2 EVALSHA Optimization

Scripts automatically use EVALSHA (by SHA1 hash) for efficiency.
If the script isn't cached on the server, it falls back to EVAL
and caches for future calls. This is transparent to your code.

=head2 scan_iter

    my $iter = $redis->scan_iter(match => 'user:*', count => 100);
    while (my $keys = await $iter->next) {
        for my $key (@$keys) { ... }
    }

Create an iterator for SCAN. Also available:

    my $hash_iter = $redis->hscan_iter('hash', match => 'field:*');
    my $set_iter  = $redis->sscan_iter('set', count => 100);
    my $zset_iter = $redis->zscan_iter('zset');

Iterators return batches. C<ZSCAN> batches are the Redis flat
member/score list.

=head1 CONNECTION POOLING

For high-throughput applications, use L<Async::Redis::Pool>:

    use Async::Redis::Pool;

    my $pool = Async::Redis::Pool->new(
        host => 'localhost',
        min  => 2,
        max  => 10,
    );

    # Use with() for automatic acquire/release
    my $result = await $pool->with(sub {
        my ($conn) = @_;
        return $conn->get('key');
    });

=head1 ERROR HANDLING

Errors are thrown as exception objects:

    eval {
        await $redis->get('key');
        1;
    } or do {
        my $error = $@;
        if (ref($error) && $error->isa('Async::Redis::Error::Connection')) {
            # Connection error
        } elsif (ref($error) && $error->isa('Async::Redis::Error::Timeout')) {
            # Timeout error
        } elsif (ref($error) && $error->isa('Async::Redis::Error::Redis')) {
            # Redis error (e.g., WRONGTYPE)
        }
    };

Exception classes:

=over 4

=item Async::Redis::Error::Connection

Connection-related errors (refused, reset, etc.)

=item Async::Redis::Error::Timeout

Timeout errors (connect, request, read).

=item Async::Redis::Error::Protocol

Protocol parsing errors.

=item Async::Redis::Error::Redis

Errors returned by Redis (WRONGTYPE, ERR, etc.)

=item Async::Redis::Error::Disconnected

Operation attempted on disconnected client.

=back

=head1 FORK SAFETY

Async::Redis is fork-safe. When a fork is detected, the child
process will automatically invalidate its connection state and
reconnect when needed. The parent retains ownership of the original
connection.

=head1 EVENT LOOP CONFIGURATION

Async::Redis uses L<Future::IO> for event loop abstraction, making it
compatible with IO::Async, UV, AnyEvent, and other event loops. However,
B<Async::Redis does not choose which event loop to use> - that's the
application's responsibility.

=head2 Default (No Configuration Needed)

B<Future::IO 0.23+> includes a built-in poll-based implementation that works
out of the box. For standalone scripts, you don't need to configure anything:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Async::Redis;

    my $redis = Async::Redis->new(host => 'localhost');
    # Just works - Future::IO uses its built-in IO::Poll backend

=head2 The Golden Rule

B<Only executable scripts should configure Future::IO.> Library modules
(C<.pm> files) should never configure the backend because they don't know
what event loop the application wants to use.

=head2 For IO::Async Applications

If your application already uses IO::Async for its event loop, load the
implementation directly:

    use IO::Async::Loop;
    require Future::IO::Impl::IOAsync;

    my $loop = IO::Async::Loop->new;

    use Async::Redis;
    my $redis = Async::Redis->new(host => 'localhost');

B<Note:> Use C<require> rather than C<Future::IO-E<gt>load_impl('IOAsync')>
for compatibility with Future::IO 0.22+ which gates C<load_impl> on the
newer C<poll> API.

=head2 For UV Applications

If your application uses UV (libuv) for its event loop:

    use UV;
    require Future::IO::Impl::UV;

    use Async::Redis;
    my $redis = Async::Redis->new(host => 'localhost');

=head2 Checking the Current Implementation

To see which Future::IO implementation is active:

    use Future::IO;
    print "Using: $Future::IO::IMPL\n";

=head1 OBSERVABILITY

OpenTelemetry integration is available:

    use OpenTelemetry::SDK;

    my $redis = Async::Redis->new(
        host        => 'localhost',
        otel_tracer => OpenTelemetry->tracer_provider->tracer('my-app'),
        otel_meter  => OpenTelemetry->meter_provider->meter('my-app'),
    );

This enables:

=over 4

=item * Distributed tracing with spans per Redis command

=item * Metrics: command latency, connection counts, errors

=item * Automatic attribute extraction (command, database, etc.)

=back

=head2 OPENTELEMETRY ARGUMENTS

Starting in 0.002000, command arguments are no longer included in spans by
default. Redis values frequently contain session tokens, user IDs, and
other PII; exporting them to a tracing backend is a privacy hazard. Pass
C<< otel_include_args => 1 >> to re-enable, and implement custom redaction
for your data shapes before doing so.

=head2 MESSAGE QUEUE DEPTH

C<message_queue_depth> limits the number of queued pubsub messages.
Callback invocation is always serialized. With C<< message_queue_depth => 1 >>
(the default), one message may be queued while one callback is still
processing; the reader pauses when that queue slot is full. Higher values
allow more messages to buffer locally before the reader pauses.

=head1 TASK LIFECYCLE

Async::Redis organizes all fire-and-forget background work (the socket
reader, reconnect attempts, auto-pipeline submit batches, the pubsub
callback driver) under a single per-client L<Future::Selector> instance,
following Paul Evans's client pattern from L<Sys::Async::Virt> and
L<IPC::MicroSocket>.

Each background task is registered with the selector via
C<< $selector->add(data => $label, f => $task_future) >>. Command
execution awaits responses via
C<< $selector->run_until_ready($response_future) >>, which pumps the
selector and propagates any task failure to the awaiting caller. The
practical guarantee: if a background task dies (including from a
coding bug that escapes explicit fatal-error handling), awaiting
callers see a typed failure rather than hanging forever.

This structure provides the five structured-concurrency properties
articulated by the L<trio|https://trio.readthedocs.io/> /
L<asyncio.TaskGroup|https://docs.python.org/3/library/asyncio-task.html#task-groups>
ecosystems:

=over

=item * GC safety - every background task is held by the selector.

=item * Error propagation - any task's failure reaches callers awaiting
the selector via C<run_until_ready>.

=item * Cancellation - socket closure propagates to pending I/O, which
fails the owning task, which the selector propagates.

=item * Scope cleanup - C<disconnect> tears down state; remaining selector
tasks unwind via their existing on_fail handlers.

=item * Local reasoning - all concurrent work on one connection is owned
by one place.

=back

There is no user-facing API for the selector; it is internal
machinery. Clients should not call C<< $redis->{_tasks} >> directly.

I<Note:> the only use of C<< Future->retain >> in this codebase is
avoided in favor of selector ownership. Any patch that introduces
C<< ->retain >> on an Async::Redis-owned Future should instead add
the task to C<< $self->{_tasks} >> so failure propagation and lifetime
ownership are consistent.

=head1 KNOWN LIMITATIONS

=over

=item * Hostname resolution is synchronous. C<connect()> calls
C<inet_aton> before the async connect, which blocks during DNS lookup.
Not covered by C<connect_timeout>.

=item * IPv6 URI hosts are not yet supported.

=item * Some generated wrappers expose mode-changing commands (HELLO,
CLIENT REPLY, MONITOR, SYNC, PSYNC) that interact poorly with the
response model. Avoid them unless you understand the protocol
consequences.

=back

=head1 SEE ALSO

=over 4

=item * L<Future::IO> - The underlying async I/O abstraction

=item * L<Future::AsyncAwait> - Async/await syntax support

=item * L<Async::Redis::Pool> - Connection pooling

=item * L<Async::Redis::Subscription> - PubSub subscriptions

=item * L<Async::Redis::Cookbook> - Practical usage recipes

=item * L<Redis> - Synchronous Redis client

=item * L<Net::Async::Redis> - Another async Redis client

=back

=head1 AUTHOR

John Napiorkowski

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
