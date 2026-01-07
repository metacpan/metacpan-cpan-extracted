#!/usr/bin/env perl

#
# Slow Redis Example - Demonstrating Non-Blocking I/O
#
# This example intentionally delays each request by 1 second to demonstrate
# that the server remains responsive and can handle concurrent requests.
#
# With blocking I/O, N requests would take N seconds sequentially.
# With non-blocking I/O, N concurrent requests still complete in ~1 second.
#
# Run:
#   REDIS_HOST=localhost pagi-server --app examples/slow-redis/app.pl --port 5001
#
# Test sequential (should take ~5 seconds):
#   for i in 1 2 3 4 5; do curl -s http://localhost:5001/ & done; wait
#
# If the above completes in ~1 second, non-blocking I/O is working!
#

use strict;
use warnings;
use Future::AsyncAwait;
use Future::IO;

# PAGI uses IO::Async - configure Future::IO to use it
Future::IO->load_impl('IOAsync');

use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/../../lib';  # For Async::Redis

use Async::Redis;

# Shared Redis connection (per-worker)
my $redis;

# Get or create Redis connection
async sub get_redis {
    return $redis if $redis && $redis->is_connected;

    $redis = Async::Redis->new(
        host => $ENV{REDIS_HOST} // 'localhost',
        port => $ENV{REDIS_PORT} // 6379,
    );
    await $redis->connect;
    return $redis;
}

# Main application
my $app = async sub {
    my ($scope, $receive, $send) = @_;
    my $type = $scope->{type} // '';
    my $path = $scope->{path} // '/';
    my $method = $scope->{method} // 'GET';

    # Handle lifespan events
    if ($type eq 'lifespan') {
        return await _handle_lifespan($scope, $receive, $send);
    }

    # Only handle HTTP
    unless ($type eq 'http') {
        await $send->({ type => 'http.response.start', status => 404, headers => [] });
        await $send->({ type => 'http.response.body', body => 'Not Found' });
        return;
    }

    # Route: GET /
    if ($path eq '/' && $method eq 'GET') {
        return await _handle_slow_request($scope, $receive, $send);
    }

    # Route: GET /fast (no delay, for comparison)
    if ($path eq '/fast' && $method eq 'GET') {
        return await _handle_fast_request($scope, $receive, $send);
    }

    # 404 for other paths
    await $send->({ type => 'http.response.start', status => 404, headers => [] });
    await $send->({ type => 'http.response.body', body => 'Not Found' });
};

# Slow request handler - delays 1 second, then returns Redis TIME
async sub _handle_slow_request {
    my ($scope, $receive, $send) = @_;

    my $start = time();
    my $worker = $$;

    my ($seconds, $microseconds, $error);

    eval {
        # Get Redis connection
        my $r = await get_redis();

        # Non-blocking sleep for 1 second
        # This is the key: the event loop can handle other requests during this sleep
        await Future::IO->sleep(1);

        # Get Redis server time (returns hashref with seconds/microseconds)
        my $time = await $r->time;
        $seconds = $time->{seconds};
        $microseconds = $time->{microseconds};
    };
    $error = $@;

    my $elapsed = sprintf("%.3f", time() - $start);

    # Handle errors gracefully
    if ($error) {
        warn "[slow-redis] Worker $worker error: $error\n";
        await $send->({
            type    => 'http.response.start',
            status  => 500,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({
            type => 'http.response.body',
            body => "Redis error: $error\n",
        });
        return;
    }

    # Build response
    my $body = <<"EOF";
Slow Redis Response
===================
Worker PID:     $worker
Redis Time:     $seconds.$microseconds
Request took:   ${elapsed}s (including 1s sleep)

This request intentionally waits 1 second to demonstrate non-blocking I/O.
Run multiple concurrent requests - they should all complete in ~1 second total!

Test with:
  for i in 1 2 3 4 5; do curl -s http://localhost:5001/ & done; wait
EOF

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            ['content-type', 'text/plain; charset=utf-8'],
            ['x-worker-pid', "$worker"],
            ['x-elapsed', $elapsed],
        ],
    });
    await $send->({
        type => 'http.response.body',
        body => $body,
    });
}

# Fast request handler - no delay, for comparison
async sub _handle_fast_request {
    my ($scope, $receive, $send) = @_;

    my $start = time();
    my $worker = $$;

    my ($seconds, $microseconds, $error);

    eval {
        my $r = await get_redis();
        my $time = await $r->time;
        $seconds = $time->{seconds};
        $microseconds = $time->{microseconds};
    };
    $error = $@;

    my $elapsed = sprintf("%.6f", time() - $start);

    if ($error) {
        warn "[slow-redis] Worker $worker error: $error\n";
        await $send->({
            type    => 'http.response.start',
            status  => 500,
            headers => [['content-type', 'text/plain']],
        });
        await $send->({
            type => 'http.response.body',
            body => "Redis error: $error\n",
        });
        return;
    }

    my $body = "Fast: worker=$worker redis_time=$seconds.$microseconds elapsed=${elapsed}s\n";

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [['content-type', 'text/plain']],
    });
    await $send->({
        type => 'http.response.body',
        body => $body,
    });
}

# Lifespan handler
async sub _handle_lifespan {
    my ($scope, $receive, $send) = @_;

    while (1) {
        my $event = await $receive->();

        if ($event->{type} eq 'lifespan.startup') {
            print STDERR "[slow-redis] Worker $$ starting...\n";

            # Pre-connect to Redis
            eval { await get_redis() };
            if ($@) {
                warn "[slow-redis] Redis connection failed: $@\n";
            } else {
                print STDERR "[slow-redis] Redis connected\n";
            }

            await $send->({ type => 'lifespan.startup.complete' });
        }
        elsif ($event->{type} eq 'lifespan.shutdown') {
            print STDERR "[slow-redis] Worker $$ shutting down...\n";
            $redis->disconnect if $redis;
            await $send->({ type => 'lifespan.shutdown.complete' });
            last;
        }
    }
}

# App coderef returned to PAGI (do 'file' returns last expression)
no warnings 'void';
$app;
__END__

=head1 NAME

slow-redis - Demonstrate non-blocking I/O with intentional delay

=head1 SYNOPSIS

    # Start Redis
    docker run -d -p 6379:6379 redis

    # Run the server
    REDIS_HOST=localhost pagi-server --app examples/slow-redis/app.pl --port 5001

    # Test single request (takes ~1 second)
    curl http://localhost:5001/

    # Test 5 concurrent requests (should still take ~1 second total!)
    time (for i in 1 2 3 4 5; do curl -s http://localhost:5001/ & done; wait)

    # Compare with fast endpoint (no delay)
    curl http://localhost:5001/fast

=head1 DESCRIPTION

This example demonstrates non-blocking I/O by intentionally sleeping for
1 second before returning a response. Despite the delay, the server can
handle many concurrent requests because the sleep is non-blocking.

With traditional blocking I/O:
- 5 sequential requests = 5 seconds
- 5 concurrent requests to a single-threaded server = 5 seconds

With non-blocking I/O (this example):
- 5 sequential requests = 5 seconds
- 5 concurrent requests = ~1 second (all sleep concurrently)

=head1 ENDPOINTS

=over 4

=item GET /

Returns Redis TIME after a 1-second non-blocking sleep.

=item GET /fast

Returns Redis TIME immediately (no delay), for comparison.

=back

=cut
