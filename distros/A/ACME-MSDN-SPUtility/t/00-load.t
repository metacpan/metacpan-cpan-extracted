#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'ACME::MSDN::SPUtility' );
}

diag( "Testing ACME::MSDN::SPUtility $ACME::MSDN::SPUtility::VERSION, Perl $], $^X" );
