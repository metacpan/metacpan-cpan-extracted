#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::WTF' ) || print "Bail out!\n";
}

diag( "Testing Acme::WTF $Acme::WTF::VERSION, Perl $], $^X" );
