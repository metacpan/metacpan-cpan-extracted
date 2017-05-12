#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'App::CCSV' );
	use_ok( 'App::CCSV::TieCSV' );
}

diag( "Testing App::CCSV $App::CCSV::VERSION, Perl $], $^X" );
