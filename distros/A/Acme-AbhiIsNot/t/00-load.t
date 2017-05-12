#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::AbhiIsNot' ) || print "Bail out!\n";
}

diag( "Testing Acme::AbhiIsNot $Acme::AbhiIsNot::VERSION, Perl $], $^X" );
