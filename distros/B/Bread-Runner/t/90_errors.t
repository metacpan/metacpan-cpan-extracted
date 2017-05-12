#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use Test::Most;
use Log::Any::Test;
use Log::Any qw($log);
use lib ('t');

use Bread::Runner;

subtest 'dies during run' => sub {
    throws_ok {
        Bread::Runner->run( 'BreadRunTest', { service => 'will_die' } );
    }
    qr/hard/, 'died';

    is( $log->msgs->[0]{message}, 'Running BreadRunTest::Die->run', 'startup log message' );
    like( $log->msgs->[1]{message}, qr/run died with hard/, 'log message' );
};
$log->clear;

subtest 'invalid run method' => sub {
    my $err_should_be =
        qr/BreadRunTest::Die does not provide any run_method: walk/;
    throws_ok {
        Bread::Runner->run(
            'BreadRunTest',
            {   service    => 'will_die',
                run_method => 'walk'
            }
        );
    }
    $err_should_be, 'died';
    like( $log->msgs->[0]{message}, $err_should_be, 'log message' );
};
$log->clear;

subtest 'invalid init method' => sub {
    my $err_should_be =
        qr/BreadRunTest does not implement a method inot/;
    throws_ok {
        Bread::Runner->run(
            'BreadRunTest',
            {   service    => 'will_die',
                init_method => 'inot'
            }
        );
    }
    $err_should_be, 'died';
    like( $log->msgs->[0]{message}, $err_should_be, 'log message' );
};
$log->clear;

subtest 'invalid service' => sub {
    my $err_should_be =
        qr/Could not find container or service for 404 in App/;
    throws_ok {
        Bread::Runner->run(
            'BreadRunTest',
            {   service    => '404',
            }
        );
    }
    $err_should_be, 'died';
    like( $log->msgs->[0]{message}, $err_should_be, 'log message' );
};
$log->clear;

subtest 'invalid app' => sub {
    my $err_should_be =
        qr/Could not find container or service for Apps in BreadRunTest/;
    throws_ok {
        Bread::Runner->run(
            'BreadRunTest',
            {   container    => 'Apps',
            }
        );
    }
    $err_should_be, 'died';
    like( $log->msgs->[0]{message}, $err_should_be, 'log message' );
};
$log->clear;

done_testing();

