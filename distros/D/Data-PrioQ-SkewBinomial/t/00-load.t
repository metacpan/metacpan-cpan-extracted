#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::PrioQ::SkewBinomial' );
}

diag( "Testing Data::PrioQ::SkewBinomial $Data::PrioQ::SkewBinomial::VERSION, Perl $], $^X" );
