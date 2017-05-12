#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
	use_ok( 'Bit::MorseSignals' );
	use_ok( 'Bit::MorseSignals::Emitter' );
	use_ok( 'Bit::MorseSignals::Receiver' );
}

diag( "Testing Bit::MorseSignals $Bit::MorseSignals::VERSION, Perl $], $^X" );
