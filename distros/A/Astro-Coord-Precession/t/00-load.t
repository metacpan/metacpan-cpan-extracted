#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Astro::Coord::Precession' ) || print "Bail out!\n";
}

diag( "Testing Astro::Coord::Precession $Astro::Coord::Precession::VERSION, Perl $], $^X" );
