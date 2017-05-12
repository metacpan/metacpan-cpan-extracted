#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Array::Splice' );
}

diag( "Testing Array::Splice $Array::Splice::VERSION, Perl $], $^X" );
