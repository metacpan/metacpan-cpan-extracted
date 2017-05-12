#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Audio::Cuefile::Parser' );
}

diag( "Testing Audio::Cuefile::Parser $Audio::Cuefile::Parser::VERSION, Perl $], $^X" );
