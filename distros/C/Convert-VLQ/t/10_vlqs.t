#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

use_ok('Convert::VLQ');

Convert::VLQ->import( qw( int2vlqs vlqs2int ) );

my $a;

my @tests = ( [ 15, 30 ], [-15, 31], [1, 2], [2, 4], [-1,3], [-2,5], [0,0],[-12345,24691] );
foreach my $pair ( @tests ) {
    $a = int2vlqs( $pair->[0] );
    is( $a, $pair->[1], "int2vlqs $pair->[0]" );
    $a = vlqs2int( $pair->[1] );
    is( $a, $pair->[0], "vlqs2int $pair->[1]" );
}