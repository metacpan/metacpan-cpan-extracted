#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DateTimeX::Easy' );
}

diag( "Testing DateTimeX::Easy $DateTimeX::Easy::VERSION, Perl $], $^X" );
