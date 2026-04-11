#!/usr/bin/env perl

use warnings;
use strict;
use v5.28;

use Test::More;
use Capture::Tiny qw(capture);

my $aep = 'bin/aep';

# Test 1: Basic command execution
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--command', 'echo', '--command-args', 'unit-test-output', '--command-norestart' );
    };
    is( $exit >> 8, 0, 'Command exits cleanly with code 0' );
    like( $stdout, qr/unit-test-output/, 'Command stdout is captured and passed through' );
    like( $stderr, qr/Starting command: echo/, 'Debug logs show command start' );
    like( $stderr, qr/Command started with PID/, 'Debug logs show PID' );
    like( $stderr, qr/Signals.*trapped/, 'Signal handlers registered' );
}

# Test 2: Command with no-restart exits after single run
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--command', '/bin/true', '--command-norestart' );
    };
    is( $exit >> 8, 0, 'true command exits 0' );
    like( $stderr, qr/no-restart flag set/, 'No-restart flag acknowledged' );
    unlike( $stderr, qr/restarting in/, 'No restart attempted' );
}

# Test 3: Command restart logic
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--command', '/bin/false', '--command-restart', '2', '--command-restart-delay', '100' );
    };
    # Should have attempted restarts
    my @restarts = ( $stderr =~ /restarting in/g );
    is( scalar @restarts, 2, 'Restarted exactly 2 times' );
    like( $stderr, qr/max restarts.*2.*reached/, 'Max restarts message shown' );
}

# Test 4: Command stderr passthrough
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--command', '/bin/sh', '--command-args', '-c,echo stderr-test >&2',
            '--command-norestart' );
    };
    like( $stderr, qr/stderr-test/, 'Command stderr is passed through' );
}

# Test 5: Scheduler starts command in standalone mode
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--command', 'echo', '--command-args', 'standalone', '--command-norestart' );
    };
    like( $stderr, qr/standalone mode, starting command/, 'Scheduler triggers standalone mode' );
}

done_testing();
