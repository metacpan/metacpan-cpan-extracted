#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Algorithm::QuineMcCluskey' );
	use_ok( 'Algorithm::QuineMcCluskey::Util' );
}

diag( "Testing Algorithm::QuineMcCluskey $Algorithm::QuineMcCluskey::VERSION, Perl $], $^X" );
