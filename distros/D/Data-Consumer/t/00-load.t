#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Consumer' );
}

diag( "Testing Data::Consumer $Data::Consumer::VERSION, Perl $], $^X" );
