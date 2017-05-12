#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Array::AsHash' );
}

diag( "Testing Array::AsHash $Array::AsHash::VERSION, Perl $], $^X" );
