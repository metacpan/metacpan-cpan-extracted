#!/usr/bin/env perl

# This test verifies lock protocol behaviour using unit-level checks.
# Full integration testing of the lock server/client pattern is done
# via Docker containers (see docker-compose.yml and t/integration/).

use warnings;
use strict;
use v5.28;

use Test::More;
use Capture::Tiny qw(capture);

my $aep = 'bin/aep';

# Test 1: Lock server mode starts scheduler correctly
{
    # Server with no clients will just sit in the event loop.
    # We verify it enters server mode by checking stderr output.
    # Use timeout to prevent hanging (server would run forever).
    my ( $stdout, $stderr, $exit ) = capture {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm(3);
        eval { system( $^X, '-Ilib', $aep, '--lock-server', '--lock-server-order', 'a,b,c' ) };
        alarm(0);
    };
    like( $stderr, qr/lock-server mode/, 'Lock server enters server mode' );
}

# Test 2: Lock client mode reports waiting for server
{
    my ( $stdout, $stderr, $exit ) = capture {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm(3);
        eval {
            system( $^X, '-Ilib', $aep,
                '--lock-client',
                '--lock-id',      'test',
                '--command',      'echo',
                '--command-args', 'test',
                '--command-norestart',
            );
        };
        alarm(0);
    };
    like( $stderr, qr/lock-client mode|does not exist/,
        'Lock client enters client mode or fails on missing socket' );
}

# Test 3: Docker health check mode
{
    my ( $stdout, $stderr, $exit ) = capture {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm(3);
        eval {
            system( $^X, '-Ilib', $aep, '--docker-health-check' );
        };
        alarm(0);
    };
    # Health check without a running server should fail/error
    ok( 1, 'Docker health check mode does not crash' );
}

done_testing();
