#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Astro::XSPEC::TableModel');
}

diag( "Testing Astro::XSPEC::TableModel $Astro::XSPEC::TableModel::VERSION, Perl $], $^X" );
