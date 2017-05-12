#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::LUID' );
}

diag( "Testing Data::LUID $Data::LUID::VERSION, Perl $], $^X" );
