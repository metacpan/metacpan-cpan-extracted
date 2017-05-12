#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Combinator' ) || print "Bail out!\n";
}

diag( "Testing Combinator $Combinator::VERSION, Perl $], $^X" );
