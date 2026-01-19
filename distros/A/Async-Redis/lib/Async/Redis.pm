package Async::Redis;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.001003';

use Future;
use Future::AsyncAwait;
use Future::IO 0.17;  # Need read/write methods
use Socket qw(pack_sockaddr_in inet_aton AF_INET SOCK_STREAM);
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
        host     => $args{host} // 'localhost',
        port     => $args{port} // 6379,
        socket   => undef,
        parser   => undef,
        connected => 0,

        # Timeout settings
        connect_timeout         => $args{connect_timeout} // 10,
        read_timeout            => $args{read_timeout} // 30,
        write_timeout           => $args{write_timeout} // 30,
        request_timeout         => $args{request_timeout} // 5,
        blocking_timeout_buffer => $args{blocking_timeout_buffer} // 2,

        # Inflight tracking with deadlines
        # Entry: { future => $f, cmd => $cmd, args => \@args, deadline => $t, sent_at => $t }
        inflight => [],

        # Response reader synchronization
        _reading_responses => 0,

        # Reconnection settings
        reconnect           => $args{reconnect} // 0,
        reconnect_delay     => $args{reconnect_delay} // 0.1,
        reconnect_delay_max => $args{reconnect_delay_max} // 60,
        reconnect_jitter    => $args{reconnect_jitter} // 0.25,
        _reconnect_attempt  => 0,

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

        # Telemetry options
        debug              => $args{debug},
        otel_tracer        => $args{otel_tracer},
        otel_meter         => $args{otel_meter},
        otel_include_args  => $args{otel_include_args} // 1,
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

    # Create socket
    my $socket = IO::Socket::INET->new(
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
    my $sockaddr = pack_sockaddr_in($self->{port}, $addr);

    # Connect with timeout using Future->wait_any
    my $connect_f = Future::IO->connect($socket, $sockaddr);
    my $sleep_f = Future::IO->sleep($self->{connect_timeout});

    # Capture a reference to the IO::Async loop for later cleanup
    # IO::Async::Future has a ->loop method that returns the loop
    if ($sleep_f->can('loop')) {
        $self->{_io_async_loop} = $sleep_f->loop;
    }

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
        close $socket;

        if ($error eq 'connect_timeout') {
            die Async::Redis::Error::Timeout->new(
                message => "Connect timed out after $self->{connect_timeout}s",
                timeout => $self->{connect_timeout},
            );
        }
        die Async::Redis::Error::Connection->new(
            message => "$error",
            host    => $self->{host},
            port    => $self->{port},
        );
    }

    # TLS upgrade if enabled
    if ($self->{tls}) {
        eval {
            $socket = await $self->_tls_upgrade($socket);
        };
        if ($@) {
            close $socket;
            die $@;
        }
    }

    $self->{socket} = $socket;
    $self->{parser} = _parser_class()->new(api => 1);
    $self->{connected} = 1;
    $self->{inflight} = [];
    $self->{_reading_responses} = 0;
    $self->{_pid} = $$;  # Track PID for fork safety

    # Run Redis protocol handshake (AUTH, SELECT, CLIENT SETNAME)
    await $self->_redis_handshake;

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
        $self->{_telemetry}->log_event('connected', "$self->{host}:$self->{port}");
    }

    return $self;
}

# Redis protocol handshake after TCP connect
async sub _redis_handshake {
    my ($self) = @_;

    # AUTH (password or username+password for ACL)
    if ($self->{password}) {
        my @auth_args = ('AUTH');
        push @auth_args, $self->{username} if $self->{username};
        push @auth_args, $self->{password};

        my $cmd = $self->_build_command(@auth_args);
        await $self->_send($cmd);

        my $response = await $self->_read_response();
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

        my $response = await $self->_read_response();
        my $result = $self->_decode_response($response);

        unless ($result && $result eq 'OK') {
            die Async::Redis::Error::Redis->new(
                message => "SELECT failed: $result",
                type    => 'ERR',
            );
        }
    }

    # CLIENT SETNAME
    if ($self->{client_name}) {
        my $cmd = $self->_build_command('CLIENT', 'SETNAME', $self->{client_name});
        await $self->_send($cmd);

        my $response = await $self->_read_response();
        # Ignore result - SETNAME failing shouldn't prevent connection
    }
}

# Check if connected to Redis
sub is_connected {
    my ($self) = @_;
    return $self->{connected} ? 1 : 0;
}

# Disconnect from Redis
sub disconnect {
    my ($self, $reason) = @_;
    $reason //= 'client_disconnect';

    my $was_connected = $self->{connected};

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
    $self->{connected} = 0;
    $self->{parser} = undef;
    $self->{_reading_responses} = 0;

    if ($was_connected && $self->{on_disconnect}) {
        $self->{on_disconnect}->($self, $reason);
    }

    # Telemetry: record disconnection
    if ($was_connected && $self->{_telemetry}) {
        $self->{_telemetry}->record_connection(-1);
        $self->{_telemetry}->log_event('disconnected', $reason);
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

# Properly close socket, cleaning up Future::IO watchers first
sub _close_socket {
    my ($self) = @_;
    my $socket = $self->{socket} or return;
    my $fileno = fileno($socket);

    # Clean up Future::IO::Impl::IOAsync watchers before closing socket
    if (defined $fileno) {
        # Access internal state of Future::IO::Impl::IOAsync to clean up watchers
        # This is necessary because the module doesn't provide a public cleanup API
        # and its ready_for_read/ready_for_write don't set up on_cancel handlers
        no strict 'refs';
        no warnings 'once';

        # Cancel pending read futures
        if (my $watching = delete ${'Future::IO::Impl::IOAsync::watching_read_by_fileno'}{$fileno}) {
            for my $f (@$watching) {
                $f->cancel if $f && !$f->is_ready;
            }
        }

        # Cancel pending write futures
        if (my $watching = delete ${'Future::IO::Impl::IOAsync::watching_write_by_fileno'}{$fileno}) {
            for my $f (@$watching) {
                $f->cancel if $f && !$f->is_ready;
            }
        }

        # Unwatch from IO::Async loop before closing socket
        if (my $loop = $self->{_io_async_loop}) {
            eval { $loop->unwatch_io(handle => $socket, on_read_ready => 1) };
            eval { $loop->unwatch_io(handle => $socket, on_write_ready => 1) };
        }
    }

    shutdown($socket, 2) if defined $fileno;
    close $socket;
    $self->{socket} = undef;
}

# Check if fork occurred and invalidate connection
sub _check_fork {
    my ($self) = @_;

    if ($self->{_pid} && $self->{_pid} != $$) {
        # Fork detected - invalidate connection (parent owns the socket)
        $self->{connected} = 0;
        $self->{socket} = undef;
        $self->{parser} = undef;
        $self->{inflight} = [];
        $self->{_reading_responses} = 0;
    
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

# Add command to inflight queue - returns queue depth
sub _add_inflight {
    my ($self, $future, $cmd, $args, $deadline) = @_;
    push @{$self->{inflight}}, {
        future   => $future,
        cmd      => $cmd,
        args     => $args,
        deadline => $deadline,
        sent_at  => Time::HiRes::time(),
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

# Ensure response reader is running - the core response queue mechanism
# Only one reader should be active at a time, processing responses in FIFO order
async sub _ensure_response_reader {
    my ($self) = @_;

    # Already reading - don't start another reader
    return if $self->{_reading_responses};

    $self->{_reading_responses} = 1;

    while (@{$self->{inflight}} && $self->{connected}) {
        my $entry = $self->{inflight}[0];

        # Read response with deadline from the entry
        my $response;
        my $read_ok = eval {
            $response = await $self->_read_response_with_deadline(
                $entry->{deadline},
                $entry->{args}
            );
            1;
        };

        if (!$read_ok) {
            my $read_error = $@;
            # Connection/timeout error - fail all inflight and abort
            $self->_fail_all_inflight($read_error);
            $self->{_reading_responses} = 0;
            return;
        }

        # Remove this entry from the queue now that we have its response
        $self->_shift_inflight;

        # Decode response (sync operation, eval works fine here)
        my $result;
        my $decode_ok = eval {
            $result = $self->_decode_response($response);
            1;
        };

        # Complete the future
        if (!$decode_ok) {
            my $decode_error = $@;
            # Redis error (like WRONGTYPE) - fail just this future
            $entry->{future}->fail($decode_error) unless $entry->{future}->is_ready;
        } else {
            # Success - complete the future with result
            $entry->{future}->done($result) unless $entry->{future}->is_ready;
        }
    }

    $self->{_reading_responses} = 0;
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

# Calculate deadline based on command type
sub _calculate_deadline {
    my ($self, $cmd, @args) = @_;

    $cmd = uc($cmd // '');

    # Blocking commands get extended deadline
    if ($cmd =~ /^(BLPOP|BRPOP|BLMOVE|BRPOPLPUSH|BLMPOP|BZPOPMIN|BZPOPMAX|BZMPOP)$/) {
        # Last arg is the timeout for these commands
        my $server_timeout = $args[-1] // 0;
        return Time::HiRes::time() + $server_timeout + $self->{blocking_timeout_buffer};
    }

    if ($cmd =~ /^(XREAD|XREADGROUP)$/) {
        # XREAD/XREADGROUP have BLOCK option
        for my $i (0 .. $#args - 1) {
            if (uc($args[$i]) eq 'BLOCK') {
                my $block_ms = $args[$i + 1] // 0;
                return Time::HiRes::time() + ($block_ms / 1000) + $self->{blocking_timeout_buffer};
            }
        }
    }

    # Normal commands use request_timeout
    return Time::HiRes::time() + $self->{request_timeout};
}

# Non-blocking TLS upgrade
async sub _tls_upgrade {
    my ($self, $socket) = @_;

    require IO::Socket::SSL;

    # Build SSL options
    my %ssl_opts = (
        SSL_startHandshake => 0,  # Don't block during start_SSL!
    );

    if (ref $self->{tls} eq 'HASH') {
        $ssl_opts{SSL_ca_file}    = $self->{tls}{ca_file} if $self->{tls}{ca_file};
        $ssl_opts{SSL_cert_file}  = $self->{tls}{cert_file} if $self->{tls}{cert_file};
        $ssl_opts{SSL_key_file}   = $self->{tls}{key_file} if $self->{tls}{key_file};

        if (exists $self->{tls}{verify}) {
            $ssl_opts{SSL_verify_mode} = $self->{tls}{verify}
                ? IO::Socket::SSL::SSL_VERIFY_PEER()
                : IO::Socket::SSL::SSL_VERIFY_NONE();
        } else {
            $ssl_opts{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_PEER();
        }
    } else {
        $ssl_opts{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_PEER();
    }

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

    while (!$self->{connected}) {
        $self->{_reconnect_attempt}++;
        my $delay = $self->_calculate_backoff($self->{_reconnect_attempt});

        eval {
            await $self->connect;
        };

        if ($@) {
            my $error = $@;

            # Fire on_error callback
            if ($self->{on_error}) {
                $self->{on_error}->($self, $error);
            }

            # Wait before next attempt
            await Future::IO->sleep($delay);
        }
    }
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

    # If disconnected and reconnect enabled, try to reconnect
    if (!$self->{connected} && $self->{reconnect}) {
        await $self->_reconnect;
    }

    die Async::Redis::Error::Disconnected->new(
        message => "Not connected",
    ) unless $self->{connected};

    # Telemetry: start span and log send
    my $span_context;
    my $start_time = Time::HiRes::time();
    if ($self->{_telemetry}) {
        $span_context = $self->{_telemetry}->start_command_span($cmd, @args);
        $self->{_telemetry}->log_send($cmd, @args);
    }

    my $raw_cmd = $self->_build_command($cmd, @args);

    # Calculate deadline based on command type
    my $deadline = $self->_calculate_deadline($cmd, @args);

    # Create response future and register in inflight queue BEFORE sending
    # This ensures responses are matched in order
    my $response_future = Future->new;
    $self->_add_inflight($response_future, $cmd, \@args, $deadline);

    my $result;
    my $error;

    my $send_ok = eval {
        # Send command
        await $self->_send($raw_cmd);
        1;
    };

    if (!$send_ok) {
        $error = $@;
        # Send failed - remove from inflight and fail
        $self->_shift_inflight;  # Remove the entry we just added
        $response_future->fail($error) unless $response_future->is_ready;
    } else {
        # Trigger the response reader (fire and forget - it runs in background)
        $self->_ensure_response_reader->retain;

        # Wait for our response future to be completed by the reader
        my $await_ok = eval {
            $result = await $response_future;
            1;
        };

        if (!$await_ok) {
            $error = $@;
        }
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
        my $timeout_f = Future::IO->sleep($remaining)->then(sub {
            return Future->fail('read_timeout');
        });

        my $wait_f = Future->wait_any($read_f, $timeout_f);
        await $wait_f;

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

    $self->{connected} = 0;
    $self->{parser} = undef;
    $self->{_reading_responses} = 0;

    if ($was_connected && $self->{on_disconnect}) {
        $self->{on_disconnect}->($self, $reason);
    }
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
        die "Redis error: $data";
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

    # Optional: install as method on this instance
    if ($def->{install}) {
        $self->_install_script_method($name);
    }

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

# Install a script as a method (internal)
sub _install_script_method {
    my ($self, $name) = @_;

    # Create closure that captures $name
    my $method = sub {
        my ($self, @args) = @_;
        return $self->run_script($name, @args);
    };

    # Install on the class (affects all instances)
    no strict 'refs';
    no warnings 'redefine';
    *{"Async::Redis::$name"} = $method;
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
    $self->{watching} = 1;
    return await $self->command('WATCH', @keys);
}

async sub unwatch {
    my ($self) = @_;
    my $result = await $self->command('UNWATCH');
    $self->{watching} = 0;
    return $result;
}

async sub multi_start {
    my ($self) = @_;
    $self->{in_multi} = 1;
    return await $self->command('MULTI');
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
    # Note: DISCARD does NOT clear watches
    return $result;
}

async sub watch_multi {
    my ($self, $keys, $callback) = @_;

    # WATCH the keys
    await $self->watch(@$keys);

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
        return [];
    }

    # Execute transaction
    $self->{in_multi} = 1;

    my $results;
    eval {
        await $self->command('MULTI');

        for my $cmd (@commands) {
            await $self->command(@$cmd);
        }

        $results = await $self->command('EXEC');
    };
    my $error = $@;

    $self->{in_multi} = 0;
    $self->{watching} = 0;

    if ($error) {
        eval { await $self->command('DISCARD') };
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

    # Create or reuse subscription
    my $sub = $self->{_subscription} //= Async::Redis::Subscription->new(redis => $self);

    # Send SUBSCRIBE command
    await $self->_send_command('SUBSCRIBE', @channels);

    # Read subscription confirmations
    for my $ch (@channels) {
        my $msg = await $self->_read_pubsub_frame();
        # Response: ['subscribe', $channel, $count]
        $sub->_add_channel($ch);
    }

    $self->{in_pubsub} = 1;

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

    my $sub = $self->{_subscription} //= Async::Redis::Subscription->new(redis => $self);

    await $self->_send_command('PSUBSCRIBE', @patterns);

    for my $p (@patterns) {
        my $msg = await $self->_read_pubsub_frame();
        $sub->_add_pattern($p);
    }

    $self->{in_pubsub} = 1;

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

    my $sub = $self->{_subscription} //= Async::Redis::Subscription->new(redis => $self);

    await $self->_send_command('SSUBSCRIBE', @channels);

    for my $ch (@channels) {
        my $msg = await $self->_read_pubsub_frame();
        $sub->_add_sharded_channel($ch);
    }

    $self->{in_pubsub} = 1;

    return $sub;
}

# Read pubsub frame (subscription confirmation or message)
async sub _read_pubsub_frame {
    my ($self) = @_;

    my $msg = await $self->_read_response();
    return $self->_decode_response($msg);
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

    die "Not connected" unless $self->{connected};

    return [] unless @$commands;

    # Wait for any inflight regular commands to complete before pipeline
    # This prevents interleaving pipeline responses with regular command responses
    await $self->_wait_for_inflight_drain;

    # Take over reading - prevent response reader from running
    $self->{_reading_responses} = 1;

    my $start_time = Time::HiRes::time();
    my @responses;
    my $count = scalar @$commands;

    my $ok = eval {
        # Send all commands
        my $data = '';
        for my $cmd (@$commands) {
            $data .= $self->_build_command(@$cmd);
        }
        await $self->_send($data);

        # Read all responses, capturing per-slot Redis errors
        for my $i (1 .. $count) {
            my $msg = await $self->_read_response();

            # Capture Redis errors inline rather than dying
            my $result;
            eval {
                $result = $self->_decode_response($msg);
            };
            if ($@) {
                # Capture the error as a string in the results
                $result = $@;
                chomp $result if defined $result;
            }
            push @responses, $result;
        }
        1;
    };

    my $error = $@;

    # Release reading lock
    $self->{_reading_responses} = 0;

    if (!$ok) {
        die $error;
    }

    # Telemetry: record pipeline metrics
    if ($self->{_telemetry}) {
        my $elapsed_ms = (Time::HiRes::time() - $start_time) * 1000;
        $self->{_telemetry}->record_pipeline($count, $elapsed_ms);
    }

    return \@responses;
}

1;

__END__

=head1 NAME

Async::Redis - Async Redis client using Future::IO

=head1 SYNOPSIS

    use Async::Redis;
    use Future::AsyncAwait;

    # Use any Future::IO-compatible event loop
    # IO::Async:
    use IO::Async::Loop;
    use Future::IO;
    Future::IO->load_impl('IOAsync');
    my $loop = IO::Async::Loop->new;

    # Or UV:   Future::IO->load_impl('UV');
    # Or Glib: Future::IO->load_impl('Glib');

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
    })->();

    $loop->run;

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
    }

=item connect_timeout => $seconds

Connection timeout. Default: 10

=item read_timeout => $seconds

Read timeout. Default: 30

=item request_timeout => $seconds

Per-request timeout. Default: 5

=item reconnect => $bool

Enable automatic reconnection. Default: 0

=item reconnect_delay => $seconds

Initial reconnect delay. Default: 0.1

=item reconnect_delay_max => $seconds

Maximum reconnect delay. Default: 60

=item reconnect_jitter => $ratio

Jitter ratio for reconnect delays. Default: 0.25

=item on_connect => $coderef

Callback when connection established.

=item on_disconnect => $coderef

Callback when connection lost.

=item on_error => $coderef

Callback for connection errors.

=item prefix => $prefix

Key prefix applied to all commands.

=item client_name => $name

CLIENT SETNAME value sent on connect.

=item debug => $bool

Enable debug logging.

=item otel_tracer => $tracer

OpenTelemetry tracer for span creation.

=item otel_meter => $meter

OpenTelemetry meter for metrics.

=back

=head1 METHODS

=head2 connect

    await $redis->connect;

Establish connection to Redis server. Returns a Future that resolves
to the Redis client instance.

=head2 disconnect

    $redis->disconnect;

Close connection gracefully.

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
    my $job = await $redis->lpop('queue');
    my $job = await $redis->rpop('queue');
    my $job = await $redis->blpop('queue', 5);     # blocking pop, 5s timeout
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

Subscribe to pattern. Returns a Subscription object.

=head2 multi

    my $results = await $redis->multi(async sub {
        my ($tx) = @_;
        $tx->set('k1', 'v1');
        $tx->incr('counter');
    });

Execute a transaction with callback.

=head2 watch

    await $redis->watch('key1', 'key2');

Watch keys for transaction.

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
        install     => 1,               # Optional: install as method
    });

Register a named Lua script for reuse. The script is automatically cached
and uses EVALSHA for efficiency.

Options:

=over 4

=item * C<keys> - Number of KEYS the script expects. Use C<'dynamic'> if
variable (first arg to run_script will be the key count).

=item * C<lua> - The Lua script source code.

=item * C<description> - Optional description for documentation.

=item * C<install> - If true, install as a method on the Async::Redis class.

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

=head2 Method Installation

For frequently used scripts, install as methods:

    $redis->define_command(cache_get => {
        keys    => 1,
        lua     => 'return redis.call("GET", KEYS[1])',
        install => 1,
    });

    # Now call directly
    my $value = await $redis->cache_get('my:key');

=head2 EVALSHA Optimization

Scripts automatically use EVALSHA (by SHA1 hash) for efficiency.
If the script isn't cached on the server, it falls back to EVAL
and caches for future calls. This is transparent to your code.

=head2 scan_iter

    my $iter = $redis->scan_iter(match => 'user:*', count => 100);
    while (my $keys = await $iter->next) {
        for my $key (@$keys) { ... }
    }

Create an iterator for SCAN. Also available: hscan_iter, sscan_iter, zscan_iter.

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

    use Try::Tiny;

    try {
        await $redis->get('key');
    } catch {
        if ($_->isa('Async::Redis::Error::Connection')) {
            # Connection error
        } elsif ($_->isa('Async::Redis::Error::Timeout')) {
            # Timeout error
        } elsif ($_->isa('Async::Redis::Error::Redis')) {
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

=head1 SEE ALSO

=over 4

=item * L<Future::IO> - The underlying async I/O abstraction

=item * L<Future::AsyncAwait> - Async/await syntax support

=item * L<Async::Redis::Pool> - Connection pooling

=item * L<Async::Redis::Subscription> - PubSub subscriptions

=item * L<Redis> - Synchronous Redis client

=item * L<Net::Async::Redis> - Another async Redis client

=back

=head1 AUTHOR

John Googoo

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
