#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Algorithm::Networksort' );
	use_ok( 'Algorithm::Networksort::Best' );
}

diag( "Testing Algorithm::Networksort $Algorithm::Networksort::VERSION, Perl $], $^X" );
