#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Blitz' ) || print "Bail out!\n";
}

diag( "Testing Blitz $Blitz::VERSION, Perl $], $^X" );
