#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::EDI' ) || print "Bail out!\n";
}

diag( "Testing Business::EDI $Business::EDI::VERSION, Perl $], $^X" );
