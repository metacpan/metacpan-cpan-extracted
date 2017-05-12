#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Array::PseudoScalar' ) || print "Bail out!\n";
}

diag( "Testing Array::PseudoScalar $Array::PseudoScalar::VERSION, Perl $], $^X" );
