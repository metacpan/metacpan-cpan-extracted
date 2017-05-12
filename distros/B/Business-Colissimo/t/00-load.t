#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::Colissimo' ) || print "Bail out!\n";
}

diag( "Testing Business::Colissimo $Business::Colissimo::VERSION, Perl $], $^X" );
