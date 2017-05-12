#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Crypt::Pwsafe' );
}

diag( "Testing Crypt::Pwsafe $Crypt::Pwsafe::VERSION, Perl $], $^X" );
