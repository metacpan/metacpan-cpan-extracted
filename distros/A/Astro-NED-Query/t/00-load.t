#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Astro::NED::Query');
}

diag( "Testing Astro::NED::Query $Astro::NED::Query::VERSION, Perl $], $^X" );
