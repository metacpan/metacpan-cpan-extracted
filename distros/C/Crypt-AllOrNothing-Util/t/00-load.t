#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Crypt::AllOrNothing::Util' );
}

diag( "Testing Crypt::AllOrNothing::Util $Crypt::AON::Util::VERSION, Perl $], $^X" );
