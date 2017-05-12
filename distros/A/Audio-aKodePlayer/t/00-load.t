#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Audio::aKodePlayer' );
}

diag( "Testing Audio::aKodePlayer $Audio::aKodePlayer::VERSION, Perl $], $^X" );
