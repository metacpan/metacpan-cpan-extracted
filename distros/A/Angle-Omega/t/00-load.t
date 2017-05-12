#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Angle::Omega' ) || print "Bail out!\n";
}

diag( "Testing Angle::Omega $Angle::Omega::VERSION, Perl $], $^X" );
