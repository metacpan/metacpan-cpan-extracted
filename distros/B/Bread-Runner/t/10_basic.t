#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use Test::Most;
use lib ('t');

use Bread::Runner;

subtest 'setup' => sub {
    my ( $bb, $service ) = Bread::Runner->setup( 'BreadRunTest',
        { service => 'api.psgi' } );
    isa_ok( $bb,      'Bread::Board::Container' );
    isa_ok( $service, 'BreadRunTest::Psgi' );
    can_ok( $service, 'run' );

    is( $service->run, 'FOO', 'now run the service' );
};

subtest 'run' => sub {
    my $rv = Bread::Runner->run( 'BreadRunTest',
        { service => 'api.psgi' } );
    is( $rv, 'FOO', 'run worked' );
};

done_testing();

