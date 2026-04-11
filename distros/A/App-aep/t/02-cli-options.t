#!/usr/bin/env perl

use warnings;
use strict;
use v5.28;

use Test::More;
use Capture::Tiny qw(capture);

my $aep = 'bin/aep';

# Test 1: --help exits cleanly and produces output
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--help' );
    };
    is( $exit >> 8, 0, '--help exits with 0' );
    like( $stdout, qr/aep.*long options/, '--help prints usage header' );
    like( $stdout, qr/--command/, '--help mentions --command' );
    like( $stdout, qr/--lock-server/, '--help mentions --lock-server' );
    like( $stdout, qr/--lock-client/, '--help mentions --lock-client' );
    like( $stdout, qr/--lock-client-host/, '--help mentions --lock-client-host (not duplicate lock-server-host)' );
    unlike( $stdout, qr/Duplicate specification/, '--help has no duplicate option warnings' );
}

# Test 2: --config-file with non-existent file fails validation
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--config-file', '/nonexistent/path.yaml', '--command-norestart' );
    };
    isnt( $exit >> 8, 0, '--config-file with bad path exits non-zero' );
}

# Test 3: Unknown options produce an error
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--not-a-real-option' );
    };
    isnt( $exit >> 8, 0, 'Unknown option exits non-zero' );
}

done_testing();
