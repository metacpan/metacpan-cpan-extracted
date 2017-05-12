#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'AI::CBR::Sim' );
	use_ok( 'AI::CBR::Case' );
	use_ok( 'AI::CBR::Retrieval' );
	use_ok( 'AI::CBR::Case::Compound' );
}

diag( "Testing AI::CBR::Case $AI::CBR::Case::VERSION, Perl $], $^X" );
