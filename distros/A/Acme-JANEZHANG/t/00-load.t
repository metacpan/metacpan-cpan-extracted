#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::JANEZHANG' ) || print "Bail out!\n";
}

diag( "Testing Acme::JANEZHANG $Acme::JANEZHANG::VERSION, Perl $], $^X" );
