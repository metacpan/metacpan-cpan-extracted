#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::FR::Town' ) || print "Bail out!\n";
}

diag( "Testing Data::FR::Town $Data::FR::Town::VERSION, Perl $], $^X" );
