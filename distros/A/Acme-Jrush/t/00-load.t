#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Jrush' ) || print "Bail out!\n";
}

diag( "Testing Acme::Jrush $Acme::Jrush::VERSION, Perl $], $^X" );
