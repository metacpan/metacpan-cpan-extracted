#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Dyoung' ) || print "Bail out!\n";
}

diag( "Testing Acme::Dyoung $Acme::Dyoung::VERSION, Perl $], $^X" );
