#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Tabulator' );
}

diag( "Testing Data::Tabulator $Data::Tabulator::VERSION, Perl $], $^X" );
