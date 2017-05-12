#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Astro::QDP::Parse');
}

diag( "Testing Astro::QDP::Parse $Astro::QDP::Parse::VERSION, Perl $], $^X" );
