#!/usr/bin/env perl

use warnings;
use strict;
use v5.28;

use Test::More;
use Capture::Tiny qw(capture);
use File::Temp qw(tempfile);
use YAML::XS;

my $aep = 'bin/aep';

# Test 1: Config file reading (YAML)
{
    my ( $fh, $config_file ) = tempfile( SUFFIX => '.yaml', UNLINK => 1 );
    print $fh YAML::XS::Dump( { 'AEP_TESTVAL' => 'from_config_file' } );
    close $fh;

    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep,
            '--config-file', $config_file,
            '--command',     'echo',
            '--command-args', 'config-test',
            '--command-norestart',
        );
    };

    is( $exit >> 8, 0, 'Config file read successfully' );
    like( $stdout, qr/config-test/, 'Command ran with config file specified' );
}

# Test 2: Environment prefix detection
{
    local $ENV{'AEP_MYVAR'} = 'test_env_value';

    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--command', 'echo', '--command-args', 'env-test', '--command-norestart' );
    };

    is( $exit >> 8, 0, 'AEP_ prefixed env vars do not break startup' );
    like( $stdout, qr/env-test/, 'Command runs with AEP_ env vars present' );
}

# Test 3: Default socket path
{
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $aep, '--command', '/bin/true', '--command-norestart' );
    };

    is( $exit >> 8, 0, 'Defaults work without explicit config' );
}

done_testing();
