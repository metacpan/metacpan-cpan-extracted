#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::Align::Subset' ) || print "Bail out!\n";
}

diag( "Testing Bio::Align::Subset $Bio::Align::Subset::VERSION, Perl $], $^X" );
