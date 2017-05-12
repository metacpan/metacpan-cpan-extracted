#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Audio::aKodePlayer' );
}

ok( grep { /^auto$/ } Audio::aKodePlayer::listSinks, 'auto sink' );
ok( grep { /^void$/ } Audio::aKodePlayer::listSinks, 'void sink' );
