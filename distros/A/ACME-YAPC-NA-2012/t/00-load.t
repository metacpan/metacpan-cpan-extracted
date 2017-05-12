#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ACME::YAPC::NA::2012' ) || print "Bail out!\n";
}

diag( "Testing ACME::YAPC::NA::2012 $ACME::YAPC::NA::2012::VERSION, Perl $], $^X" );
