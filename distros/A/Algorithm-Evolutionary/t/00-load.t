#!perl -T

use Test::More tests => 2;
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

BEGIN {
	use_ok( 'Algorithm::Evolutionary' );
	use_ok( 'Algorithm::Evolutionary', qw( Fitness::ECC Op::Crossover Individual::Vector )); # Just three examples, testing the import mechanism
}

diag( "Testing Algorithm::Evolutionary $Algorithm::Evolutionary::VERSION, Perl $], $^X" );
