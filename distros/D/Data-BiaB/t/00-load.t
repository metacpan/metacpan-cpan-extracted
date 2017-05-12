#! perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Data::Hexify' );
	use_ok( 'MIDI' );
	use_ok( 'Data::BiaB' );
	use_ok( 'Data::BiaB::MIDI' );
}

diag( "Testing Data::BiaB $Data::BiaB::VERSION, Perl $], $^X" );
