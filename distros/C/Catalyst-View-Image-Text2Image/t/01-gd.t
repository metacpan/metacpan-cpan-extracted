#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'GD::Simple' ) || print "Bail out!\n";
}

diag( "Testing GD::Simple, Perl $], $^X" );
