#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::ICal::RDF' ) || print "Bail out!\n";
}

diag( "Testing Data::ICal::RDF $Data::ICal::RDF::VERSION, Perl $], $^X" );
