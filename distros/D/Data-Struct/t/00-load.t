#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Struct' );
}

diag( "Testing Data::Struct $Data::Struct::VERSION, Perl $], $^X" );
