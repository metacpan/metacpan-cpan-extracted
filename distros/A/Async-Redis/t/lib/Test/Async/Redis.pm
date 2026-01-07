package Test::Async::Redis;

use strict;
use warnings;
use parent 'Exporter';
use Future::AsyncAwait;
use Test2::V0;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use IO::Async::Process;
use Future::IO;
use Async::Redis;

# For testing, we use IO::Async as our concrete event loop.
Future::IO->load_impl('IOAsync');

# Suppress known harmless warnings from IO::Async/Future::IO cleanup
# These occur because Future::IO::Impl::IOAsync doesn't set up on_cancel
# handlers for ready_for_read/ready_for_write, so when sockets are closed
# during disconnect, the cleanup callbacks may access closed handles.
# See: https://metacpan.org/pod/Future::IO::Impl::IOAsync
$SIG{__WARN__} = sub {
    my $msg = shift;
    # Suppress IO::Async cleanup warnings about closed socket fileno
    return if $msg =~ /uninitialized value.*fileno/i;
    return if $msg =~ /uninitialized value in (?:hash element|delete)/;
    warn $msg;
};

our @EXPORT_OK = qw(
    init_loop
    get_loop
    run
    await_f
    skip_without_redis
    cleanup_keys
    with_timeout
    fails_with
    delay
    run_command
    run_docker
    measure_ticks
    redis_host
    redis_port
);

our %EXPORT_TAGS = (
    # Import with :redis to auto-skip if Redis unavailable
    # Usage: use Test::Async::Redis ':redis';
    redis => [qw(init_loop get_loop run await_f skip_without_redis cleanup_keys delay redis_host redis_port)],
);

sub import {
    my $class = shift;
    my @args = @_;

    my $auto_skip = 0;
    @args = grep {
        if ($_ eq ':redis') { $auto_skip = 1; 0 }
        else { 1 }
    } @args;

    # If :redis tag, add the standard exports
    if ($auto_skip) {
        push @args, @{$EXPORT_TAGS{redis}};
    }

    # Do the normal Exporter import
    $class->export_to_level(1, $class, @args);

    # Auto-skip if :redis was requested (after exports are done)
    if ($auto_skip) {
        init_loop();
        _check_redis();
    }
}

our $loop;
our $test_redis;  # Shared Redis connection from skip_without_redis

# Get Redis connection details from environment
sub redis_host { $ENV{REDIS_HOST} // 'localhost' }
sub redis_port { $ENV{REDIS_PORT} // 6379 }

# Initialize the event loop (call once at test start)
sub init_loop {
    $loop = IO::Async::Loop->new;
    return $loop;
}

# Get the current loop
sub get_loop {
    $loop //= init_loop();
    return $loop;
}

# Run an async block and return result - the main test helper
# Usage: my $result = run { $redis->get('key') };  # returns Future
sub run (&) {
    my ($code) = @_;
    my $result = $code->();

    # If it's a Future, await it
    if (ref($result) && $result->isa('Future')) {
        get_loop()->await($result);
        return $result->get;
    }

    # Otherwise return as-is
    return $result;
}

# Await a future directly - backward compatible alias
# Usage: my $result = await_f($redis->get('key'));
sub await_f {
    my ($f) = @_;
    get_loop()->await($f);
    return $f->get;
}

# Check Redis at import time (called from import)
sub _check_redis {
    my $redis = eval {
        my $r = Async::Redis->new(
            host => redis_host(),
            port => redis_port(),
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    if ($redis) {
        $test_redis = $redis;
        return;
    }
    skip_all("Redis not available at " . redis_host() . ":" . redis_port() . ": $@");
}

# Skip if no Redis available - returns connected Redis object
sub skip_without_redis {
    return $test_redis if $test_redis;

    my $redis = eval {
        my $r = Async::Redis->new(
            host => redis_host(),
            port => redis_port(),
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    if ($redis) {
        $test_redis = $redis;
        return $redis;
    }
    skip_all("Redis not available at " . redis_host() . ":" . redis_port() . ": $@");
}

# Clean up test keys
async sub cleanup_keys {
    my ($redis, $pattern) = @_;
    my $keys = await $redis->keys($pattern);
    return unless @$keys;
    await $redis->del(@$keys);
}

# Test with timeout wrapper
async sub with_timeout {
    my ($timeout, $future) = @_;
    my $timeout_f = Future::IO->sleep($timeout)->then(sub {
        Future->fail("Test timeout after ${timeout}s");
    });
    return await Future->wait_any($future, $timeout_f);
}

# Assert Future fails with specific error type
sub fails_with {
    my ($future, $error_class, $message) = @_;
    my $error;
    eval { run { $future } } or $error = $@;
    ok($error && ref($error) && $error->isa($error_class), $message)
        or diag("Expected $error_class, got: " . (ref($error) || $error // 'undef'));
}

# Async delay
async sub delay {
    my ($seconds) = @_;
    await Future::IO->sleep($seconds);
}

# Run external command asynchronously
async sub run_command {
    my (@cmd) = @_;
    my $future = get_loop()->new_future;
    my $stdout = '';
    my $stderr = '';

    my $process = IO::Async::Process->new(
        command => \@cmd,
        stdout => { into => \$stdout },
        stderr => { into => \$stderr },
        on_finish => sub {
            my ($self, $exitcode) = @_;
            if ($exitcode == 0) {
                $future->done($stdout);
            } else {
                $future->fail("Command [@cmd] failed (exit $exitcode): $stderr");
            }
        },
    );

    get_loop()->add($process);
    return await $future;
}

# Docker-specific helper
async sub run_docker {
    my (@args) = @_;
    return await run_command('docker', @args);
}

# Measure event loop ticks during an operation
async sub measure_ticks {
    my ($future, $interval) = @_;
    $interval //= 0.01;  # 10ms default

    my @ticks;
    my $timer = IO::Async::Timer::Periodic->new(
        interval => $interval,
        on_tick => sub { push @ticks, time() },
    );
    get_loop()->add($timer);
    $timer->start;

    my @result;
    my $error;
    eval {
        @result = await $future;
        1;
    } or $error = $@;

    $timer->stop;
    get_loop()->remove($timer);

    die $error if $error;
    return (\@result, scalar(@ticks));
}

1;

__END__

=head1 NAME

Test::Async::Redis - Test utilities for Async::Redis

=head1 SYNOPSIS

    use Test::Lib;
    use Test::Async::Redis ':redis';
    use Future::AsyncAwait;

    # Tests auto-skip if Redis unavailable
    # Use run {} to execute async code in tests:

    my $result = run {
        my $redis = Async::Redis->new;
        await $redis->connect;
        await $redis->set('key', 'value');
        await $redis->get('key');
    };
    is($result, 'value', 'got value');

    # Or get Redis from skip_without_redis:
    my $redis = skip_without_redis();
    my $pong = run { await $redis->ping };
    is($pong, 'PONG', 'ping works');

=head1 DESCRIPTION

Test utilities for Async::Redis using async/await.

=head1 FUNCTIONS

=over 4

=item run { async code }

Execute an async block and return its result. This is the main
test helper - wrap any async operations in run { }.

=item skip_without_redis()

Skip all tests if Redis is not available. Returns a connected
Async::Redis object if successful.

=item cleanup_keys($redis, $pattern)

Async function to delete all keys matching pattern.

=item with_timeout($seconds, $future)

Wrap a future with a timeout.

=item fails_with($future, $error_class, $message)

Assert that a future fails with the specified error class.

=item delay($seconds)

Async function that delays for the specified time.

=item run_command(@cmd)

Async function to run an external command.

=item run_docker(@args)

Async function to run a docker command.

=item measure_ticks($future, $interval)

Measure event loop ticks during a future's execution.

=back

=cut
