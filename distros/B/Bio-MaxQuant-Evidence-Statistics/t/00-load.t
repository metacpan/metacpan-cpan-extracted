#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::MaxQuant::Evidence::Statistics' ) || print "Bail out!\n";
}

diag( "Testing Bio::MaxQuant::Evidence::Statistics $Bio::MaxQuant::Evidence::Statistics::VERSION, Perl $], $^X" );
