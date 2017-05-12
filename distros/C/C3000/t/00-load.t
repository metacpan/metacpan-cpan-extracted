#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'C3000' ) || print "Bail out!\n";
}

diag( "Testing C3000 $C3000::VERSION, Perl $], $^X" );
