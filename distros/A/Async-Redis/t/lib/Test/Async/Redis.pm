package Test::Async::Redis;

use strict;
use warnings;
use parent 'Exporter';
use Future::AsyncAwait;
use Test2::V0;
use Future::IO;
use Async::Redis;

our @EXPORT_OK = qw(
    run
    await_f
    skip_without_redis
    cleanup_keys
    with_timeout
    fails_with
    delay
    redis_host
    redis_port
    inject_eof
    inject_unexpected_frame
    force_read_timeout
);

our %EXPORT_TAGS = (
    # Import with :redis to auto-skip if Redis unavailable
    # Usage: use Test::Async::Redis ':redis';
    redis => [qw(run await_f skip_without_redis cleanup_keys delay redis_host redis_port)],
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
        _check_redis();
    }
}

our $test_redis;  # Shared Redis connection from skip_without_redis

# Get Redis connection details from environment
sub redis_host { $ENV{REDIS_HOST} // 'localhost' }
sub redis_port { $ENV{REDIS_PORT} // 6379 }

# Run an async block and return result - the main test helper
# Usage: my $result = run { $redis->get('key') };  # returns Future
sub run (&) {
    my ($code) = @_;
    my $result = $code->();

    # If it's a Future, await it
    if (ref($result) && $result->isa('Future')) {
        return _pump_until_ready($result);
    }

    # Otherwise return as-is
    return $result;
}

# Await a future directly
# Usage: my $result = await_f($redis->get('key'));
sub await_f {
    my ($f) = @_;
    return _pump_until_ready($f);
}

# Drive the Future::IO event loop until a future resolves.
# Handles both Future::IO futures (which have _await_once) and
# plain Future->new objects (e.g. from AutoPipeline) that need
# the event loop pumped externally.
sub _pump_until_ready {
    my ($f) = @_;
    until ($f->is_ready) {
        Future::IO->sleep(0)->get;
    }
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

# Force EOF on the socket under the reader. Next read returns 0 bytes,
# triggering the reader's EOF handling path. Uses shutdown() rather
# than close() so the file descriptor stays valid for Future::IO's
# select loop — close() on an fh that Future::IO has an active poller
# on leaves a stale watcher whose fileno is undef, which taints select()
# with uninit warnings.
sub inject_eof {
    my ($redis) = @_;
    shutdown($redis->{socket}, 2) if $redis->{socket};
}

# Feed bytes directly into the parser, bypassing the socket. Useful
# for exercising the reader's decode/dispatch path with a crafted frame.
sub inject_unexpected_frame {
    my ($redis, $raw_bytes) = @_;
    $redis->{parser}->parse($raw_bytes) if $redis->{parser};
}

# Synthesize a fatal timeout directly. Routes through the detach-first
# _reader_fatal path so the typed Async::Redis::Error::Timeout is
# propagated to all inflight futures (not a generic cancellation).
sub force_read_timeout {
    my ($redis) = @_;
    require Async::Redis::Error::Timeout;
    $redis->_reader_fatal(Async::Redis::Error::Timeout->new(
        message => "synthetic timeout for test",
        timeout => 0,
    ));
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

Test utilities for Async::Redis using async/await. Uses Future::IO's
built-in default implementation (IO::Poll based) for event loop management.

=head1 FUNCTIONS

=over 4

=item run { async code }

Execute an async block and return its result. This is the main
test helper - wrap any async operations in run { }.

=item await_f($future)

Await a future and return its result.

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

=item redis_host()

Returns the Redis host from REDIS_HOST env var (default: localhost).

=item redis_port()

Returns the Redis port from REDIS_PORT env var (default: 6379).

=item inject_eof($redis)

Force EOF on the underlying socket via C<shutdown(..., 2)> so the next
sysread returns 0 bytes. Triggers the reader's EOF handling path. Used
in adverse-interleaving tests to simulate abrupt server disconnect.
C<shutdown> is used in preference to C<close> so the file descriptor
stays valid for any active Future::IO poller watching the socket.

=item inject_unexpected_frame($redis, $raw_bytes)

Feed raw bytes directly into the RESP parser, bypassing the socket.
Useful for exercising the reader's decode/dispatch path with a crafted
or malformed frame without needing a live server to send it.

=item force_read_timeout($redis)

Synthesize a fatal timeout by calling C<_reader_fatal> with a typed
C<Async::Redis::Error::Timeout> object. All inflight futures receive
the typed error via the detach-first path rather than generic
cancellation.

=back

=cut
