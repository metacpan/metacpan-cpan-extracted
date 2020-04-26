#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Astro::DSS::JPEG' ) || print "Bail out!\n";
}

diag( "Testing Astro::DSS::JPEG $Astro::DSS::JPEG::VERSION, Perl $], $^X" );
