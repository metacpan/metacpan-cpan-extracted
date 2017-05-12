#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Convert::BaseN' );
}

diag( "Testing Convert::BaseN $Convert::BaseN::VERSION, Perl $], $^X" );
