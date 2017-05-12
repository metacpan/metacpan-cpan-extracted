#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Testing' ) || print "Bail out!\n";
}

diag( "Testing Acme::Testing $Acme::Testing::VERSION, Perl $], $^X" );
