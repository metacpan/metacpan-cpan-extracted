#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::GRYLLIDA::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::GRYLLIDA::Utils $Acme::GRYLLIDA::Utils::VERSION, Perl $], $^X" );
