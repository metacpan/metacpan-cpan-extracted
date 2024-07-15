#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Astro::MoonPhase::Simple' ) || print "Bail out!\n";
}

diag( "Testing Astro::MoonPhase::Simple $Astro::MoonPhase::Simple::VERSION, Perl $], $^X" );
