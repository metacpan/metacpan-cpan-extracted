#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Convert::Age' );
}

diag( "Testing Convert::Age $Convert::Age::VERSION, Perl $], $^X" );
