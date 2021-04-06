#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Astro::Coord::Constellations' ) || print "Bail out!\n";
}

diag( "Testing Astro::Coord::Constellations $Astro::Coord::Constellations::VERSION, Perl $], $^X" );
