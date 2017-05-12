#!perl -T

use Test::More tests => 2;
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

BEGIN {
	use_ok( 'Algorithm::Evolutionary::Utils' );
	use_ok( 'Algorithm::Evolutionary::Utils', qw(entropy genotypic_entropy hamming consensus average random_bitstring random_number_array decode_string vector_compare )); # Just three examples, testing the import mechanism
}

diag( "Testing Algorithm::Evolutionary::Utils $Algorithm::Evolutionary::Utils::VERSION, Perl $], $^X" );
