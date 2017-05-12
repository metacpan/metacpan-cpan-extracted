#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Audio::Extract::PCM' );
}

diag( "Testing Audio::Extract::PCM $Audio::Extract::PCM::VERSION, Perl $], $^X" );
