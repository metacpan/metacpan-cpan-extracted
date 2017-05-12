#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cluster::Similarity' );
}

diag( "Testing Cluster::Similarity $Cluster::Similarity::VERSION, Perl $], $^X" );
