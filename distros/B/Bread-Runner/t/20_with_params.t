#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use Test::Most;
use lib ('t');

use Bread::Runner;

@ARGV = qw(--string bar --flag);
my ( $bb, $service ) =
    Bread::Runner->setup( 'BreadRunTest', { service => 'some_script' } );
isa_ok( $bb,      'Bread::Board::Container' );
isa_ok( $service, 'BreadRunTest::Commandline' );
can_ok( $service, 'run' );

is( $service->string, 'bar', 'param: string' );
is( $service->flag,   1,     'param: flag' );
is( $service->int,    42,    'param: int default' );
cmp_deeply( $service->array, undef, 'param: array empty' );

is( $service->run, "We did it, let's head home!", 'now run the service' );

done_testing();

