# t/93-socket-cleanup/close-with-watchers.t
#
# Test that demonstrates the problem with calling close() on a socket
# that still has Future::IO watchers registered.
#
# The issue: When you close() a filehandle, its fileno becomes invalid.
# If Future::IO still has watchers registered on that fileno, the poll
# loop can't properly unregister them (it needs the fileno to do so).
#
# This can cause warnings, errors, or undefined behavior depending on
# the Future::IO backend (IO::Async, UV, etc.)
#
# EXPECTED BEHAVIOR BEFORE FIX:
#   These tests will FAIL with errors like:
#   "Can't call method 'done' on an undefined value at Future/IO/Impl/IOAsync.pm"
#   This demonstrates the bug where close() corrupts Future::IO's internal state.
#
# EXPECTED BEHAVIOR AFTER FIX:
#   All tests should pass with no warnings or errors.

use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(skip_without_redis run);

# Ignore SIGPIPE — this test deliberately closes sockets while writes are pending
$SIG{PIPE} = 'IGNORE';

SKIP: {
    my $redis = skip_without_redis();

    subtest 'disconnect with pending read captures fileno issues' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Start a blocking read command - this registers a watcher with Future::IO
        # BLPOP will block for up to 1 second waiting for data
        my $blocking_future = $r->blpop('nonexistent:key:for:close:test', 1);

        # Get the socket fileno before disconnect
        my $fileno_before = fileno($r->{socket});
        ok(defined $fileno_before, "socket has valid fileno before disconnect: $fileno_before");

        # Now disconnect while the BLPOP is still waiting
        # This is where the problem occurs - close() is called while
        # Future::IO still has a read watcher on this fileno
        $r->disconnect;

        # The socket should be gone now
        ok(!defined $r->{socket}, 'socket is undef after disconnect');

        # Wait a moment for any async cleanup to propagate
        run { Future::IO->sleep(0.1) };

        # Check for warnings related to fileno issues
        # Different backends may produce different warnings:
        # - "Bad file descriptor"
        # - "Invalid argument"
        # - Warnings about removing non-existent watchers
        my @fileno_warnings = grep {
            /fileno|file descriptor|invalid|bad fd|not registered/i
        } @warnings;

        # This is what we're testing - ideally there should be NO warnings
        # If there are warnings, it indicates the close() happened before
        # the poll loop could unregister its watchers
        if (@fileno_warnings) {
            diag "Captured fileno-related warnings (this indicates the bug):";
            diag "  $_" for @fileno_warnings;
        }

        # For now, just note any warnings - this test documents the behavior
        # After the fix, we expect zero warnings
        note "Total warnings captured: " . scalar(@warnings);
        for my $w (@warnings) {
            note "  Warning: $w";
        }

        # The blocking future should be cancelled/failed
        ok($blocking_future->is_ready, 'blocking future is ready after disconnect');
        ok($blocking_future->is_cancelled || $blocking_future->is_failed,
           'blocking future is cancelled or failed');

        pass('disconnect completed without crashing');
    };

    subtest 'rapid connect/disconnect cycles stress test' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        # Rapidly connect and disconnect, sometimes with pending operations
        for my $i (1..10) {
            my $r = Async::Redis->new(
                host => $ENV{REDIS_HOST} // 'localhost',
            );
            run { $r->connect };

            # On odd iterations, start an operation before disconnect
            if ($i % 2) {
                my $f = $r->ping;  # Start a command
                $r->disconnect;   # Disconnect while it's pending
            } else {
                $r->disconnect;   # Clean disconnect
            }
        }

        # Give async cleanup time to complete
        run { Future::IO->sleep(0.2) };

        my @fileno_warnings = grep {
            /fileno|file descriptor|invalid|bad fd|not registered/i
        } @warnings;

        if (@fileno_warnings) {
            diag "Stress test captured fileno warnings:";
            diag "  $_" for @fileno_warnings;
        }

        # Document the behavior - after fix, expect zero warnings
        is(scalar(@fileno_warnings), 0,
           'no fileno-related warnings during rapid connect/disconnect')
            or diag "Got " . scalar(@fileno_warnings) . " warnings";

        pass('stress test completed without crashing');
    };

    subtest 'disconnect during concurrent commands' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Fire off multiple concurrent commands
        my @futures;
        for my $i (1..5) {
            push @futures, $r->set("close:test:$i", "value:$i");
        }

        # Disconnect immediately while commands are in flight
        $r->disconnect;

        # All futures should be ready (completed, failed, or cancelled)
        run { Future::IO->sleep(0.1) };

        for my $i (0..$#futures) {
            ok($futures[$i]->is_ready, "future $i is ready after disconnect");
        }

        my @fileno_warnings = grep {
            /fileno|file descriptor|invalid|bad fd|not registered/i
        } @warnings;

        is(scalar(@fileno_warnings), 0,
           'no fileno-related warnings during concurrent disconnect')
            or do {
                diag "Warnings captured:";
                diag "  $_" for @fileno_warnings;
            };

        pass('concurrent command disconnect completed');
    };
}

done_testing;
