#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::fastAPD' ) || print "Bail out!\n";
}

diag( "Testing Bio::fastAPD $Bio::fastAPD::VERSION, Perl $], $^X" );
