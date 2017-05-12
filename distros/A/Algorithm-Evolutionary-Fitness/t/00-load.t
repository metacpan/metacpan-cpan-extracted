#!perl -T

use Test::More tests => 1;
use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

BEGIN {
	use_ok( 'Algorithm::Evolutionary::Fitness' );
}

diag( "Testing Algorithm::Evolutionary::Fitness $Algorithm::Evolutionary::Fitness::VERSION, Perl $], $^X" );
