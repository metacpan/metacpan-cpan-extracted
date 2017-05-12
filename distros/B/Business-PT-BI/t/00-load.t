#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::PT::BI' );
}

diag( "Testing Business::PT::BI $Business::PT::BI::VERSION, Perl $], $^X" );
