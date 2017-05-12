#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::ResultSet' );
}

diag( "Testing Data::ResultSet $Data::ResultSet::VERSION, Perl $], $^X" );
