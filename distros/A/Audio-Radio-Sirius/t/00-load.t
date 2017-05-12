#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Audio::Radio::Sirius' );
}

diag( "Testing Audio::Radio::Sirius $Audio::Radio::Sirius::VERSION, Perl $], $^X" );
