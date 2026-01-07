#!/usr/bin/env perl

#
# Multi-Worker Chat using PAGI + Async::Redis
#
# This is a port of PAGI's websocket-chat-v2 example, adapted to use
# Redis for state management and PubSub for cross-worker broadcasting.
#
# Key difference: the original uses in-memory state (single worker only).
# This version stores state in Redis, enabling multi-worker deployments.
#
# Run with multiple workers:
#   REDIS_HOST=localhost pagi-server --app examples/pagi-chat/app.pl --port 5000 --workers 4
#
# Then open http://localhost:5000 in multiple browser tabs.
# Messages will sync across all workers via Redis PubSub.
#

use strict;
use warnings;
use Future;
use Future::AsyncAwait;

# PAGI uses IO::Async - configure Future::IO to use it
#use IO::Async::Loop;
use Future::IO;
Future::IO->load_impl('IOAsync');

use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/lib';
use lib dirname(__FILE__) . '/../../lib';  # For Async::Redis

use ChatApp::State qw(init_redis);
use ChatApp::HTTP;
use ChatApp::WebSocket;

# Pre-instantiate handlers
my $http_handler = ChatApp::HTTP::handler();
my $ws_handler = ChatApp::WebSocket::handler();

# Track if Redis is initialized for this worker
my $redis_initialized = 0;

# Ensure Redis is initialized (called on first request per worker)
async sub ensure_redis {
    return if $redis_initialized;

    my $result = await init_redis()->catch(sub {
        my ($err) = @_;
        warn "[worker $$] Redis init failed: $err";
        return Future->done(undef);  # Continue without Redis
    });

    if ($result) {
        $redis_initialized = 1;
        print STDERR "[worker $$] Redis initialized\n";
    }
}

# Logging middleware
sub with_logging {
    my ($app) = @_;

    return async sub {
        my ($scope, $receive, $send) = @_;
        my $start = time();
        my $type = $scope->{type};
        my $path = $scope->{path} // '-';
        my $method = $scope->{method} // '-';

        my $status = '-';
        my $wrapped_send = async sub {
            my ($event) = @_;
            if ($event->{type} =~ /\.start$/ && defined $event->{status}) {
                $status = $event->{status};
            }
            await $send->($event);
        };

        eval { await $app->($scope, $receive, $wrapped_send) };
        my $error = $@;

        my $duration = sprintf("%.3f", time() - $start);
        say STDERR "[$type] $method $path $status ${duration}s (worker $$)";

        die $error if $error;
    };
}

# Main application
my $app = with_logging(async sub {
    my ($scope, $receive, $send) = @_;
    my $type = $scope->{type} // '';
    my $path = $scope->{path} // '/';

    # Handle lifespan events
    if ($type eq 'lifespan') {
        return await _handle_lifespan($scope, $receive, $send);
    }

    # Ensure Redis is ready (lazy init per worker)
    await ensure_redis();

    # Route WebSocket
    if ($type eq 'websocket' && $path eq '/ws/chat') {
        return await $ws_handler->($scope, $receive, $send);
    }

    # Route HTTP
    if ($type eq 'http') {
        return await $http_handler->($scope, $receive, $send);
    }

    # SSE not implemented - return 404
    if ($type eq 'sse') {
        await $send->({ type => 'http.response.start', status => 404, headers => [] });
        await $send->({ type => 'http.response.body', body => 'SSE not implemented' });
        return;
    }

    die "Unsupported scope type: $type";
});

async sub _handle_lifespan {
    my ($scope, $receive, $send) = @_;

    while (1) {
        my $event = await $receive->();

        if ($event->{type} eq 'lifespan.startup') {
            say STDERR "[lifespan] Worker $$ starting...";
            await $send->({ type => 'lifespan.startup.complete' });
        }
        elsif ($event->{type} eq 'lifespan.shutdown') {
            say STDERR "[lifespan] Worker $$ shutting down...";
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

PAGI Chat - Multi-Worker Redis-backed Chat Example

=head1 DESCRIPTION

Demonstrates Async::Redis enabling multi-worker real-time applications.

=head1 USAGE

    # Start Redis
    docker run -d -p 6379:6379 redis

    # Run with multiple workers
    REDIS_HOST=localhost pagi-server \
        --app examples/pagi-chat/app.pl \
        --port 5000 \
        --workers 4

    # Open http://localhost:5000 in multiple browser tabs

=cut
