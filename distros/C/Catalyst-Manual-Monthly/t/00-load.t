#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Manual::Monthly' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Manual::Monthly $Catalyst::Manual::Monthly::VERSION, Perl $], $^X" );
