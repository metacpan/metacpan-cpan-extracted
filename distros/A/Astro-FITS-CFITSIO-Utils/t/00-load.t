#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Astro::FITS::CFITSIO::Utils');
}

diag( "Testing Astro::FITS::CFITSIO::Utils $Astro::FITS::CFITSIO::Utils::VERSION, Perl $], $^X" );
