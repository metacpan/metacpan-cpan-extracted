#!/usr/bin/perl

use Test::More qw(
	no_plan
	);

BEGIN {
  use_ok('CAD::Drawing::IO::DWGI');
}

diag( "Testing CAD::Drawing::IO::DWGI $CAD::Drawing::IO::DWGI::VERSION" );
