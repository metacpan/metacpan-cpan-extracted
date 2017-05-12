#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DataExtract::FixedWidth' );
}

diag( "Testing DataExtract::FixedWidth $DataExtract::FixedWidth::VERSION, Perl $], $^X" );
