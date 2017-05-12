#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use ACME::THEDANIEL::Utils;

BEGIN {
    use_ok( 'ACME::THEDANIEL::Utils' ) || print "Bail out!\n";
}

is( ACME::THEDANIEL::Utils::sum( 1, 2, 3, 4 ), 10, "multiple numbers sum" );
is( ACME::THEDANIEL::Utils::sum( 1 ), 1, "single number sum" );

throws_ok( sub { ACME::THEDANIEL::Utils::sum( 1, 2, "Three" ) }, qr/Invalid input: Three/, "One bad arg out of many");
throws_ok( sub { ACME::THEDANIEL::Utils::sum( "Three" ) }, qr/Invalid input: Three/, "invalid single input");

is( ACME::THEDANIEL::Utils::sum(), undef, "empty input" );
