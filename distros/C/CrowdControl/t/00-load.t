#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CrowdControl' );
}

diag( "Testing CrowdControl $CrowdControl::VERSION, Perl $], $^X" );
