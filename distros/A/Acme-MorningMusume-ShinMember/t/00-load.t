#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::MorningMusume::ShinMember' );
}

diag( "Testing Acme::MorningMusume::ShinMember $Acme::MorningMusume::ShinMember::VERSION, Perl $], $^X" );
