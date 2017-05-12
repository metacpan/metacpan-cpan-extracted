#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Audio::Ofa' );
}

diag( "Testing Audio::Ofa $Audio::Ofa::VERSION, Perl $], $^X" );
