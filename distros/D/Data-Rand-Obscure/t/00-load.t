#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Rand::Obscure' );
}

diag( "Testing Data::Rand::Obscure $Data::Rand::Obscure::VERSION, Perl $], $^X" );
