#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bison' ) || print "Bail out!\n";
}

diag( "Testing Bison $Bison::VERSION, Perl $], $^X" );
