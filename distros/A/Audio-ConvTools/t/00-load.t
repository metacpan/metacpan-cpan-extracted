#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Audio::ConvTools' );
}

diag( "Testing Audio::ConvTools $Audio::ConvTools::VERSION, Perl $], $^X" );
