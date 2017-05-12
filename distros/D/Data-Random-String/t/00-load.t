#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Random::String' );
}

diag( "Testing Data::Random::String $Data::Random::String::VERSION, Perl $], $^X" );
