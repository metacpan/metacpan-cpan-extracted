#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Crypt::AllOrNothing' );
}

diag( "Testing Crypt::AllOrNothing $Crypt::AllOrNothing::VERSION, Perl $], $^X" );
