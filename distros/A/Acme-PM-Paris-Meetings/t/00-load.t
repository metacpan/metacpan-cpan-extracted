#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::PM::Paris::Meetings' );
}

diag( "Testing Acme::PM::Paris::Meetings $Acme::PM::Paris::Meetings::VERSION, Perl $], $^X" );
