#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ACME::ltharris' ) || print "Bail out!\n";
}

diag( "Testing ACME::ltharris $ACME::ltharris::VERSION, Perl $], $^X" );
