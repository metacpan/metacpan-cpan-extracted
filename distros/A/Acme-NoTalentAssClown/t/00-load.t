#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::NoTalentAssClown' );
}

diag( "Testing Acme::NoTalentAssClown $Acme::NoTalentAssClown::VERSION, Perl $], $^X" );
