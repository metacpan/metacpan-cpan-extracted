#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Algorithm::Bitonic::Sort' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::Bitonic::Sort $Algorithm::Bitonic::Sort::VERSION, Perl $], $^X" );
