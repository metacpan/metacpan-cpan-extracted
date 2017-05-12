#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Archive::Mbox' );
}

diag( "Testing Acme::Archive::Mbox $Acme::Archive::Mbox::VERSION, Perl $], $^X" );
