#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Authentication::Store::MongoDB' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Authentication::Store::MongoDB $Catalyst::Authentication::Store::MongoDB::VERSION, Perl $], $^X" );
