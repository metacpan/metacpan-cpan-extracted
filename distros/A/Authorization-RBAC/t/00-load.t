#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authorization::RBAC' ) || print "Bail out!\n";
}

diag( "Testing Authorization::RBAC $Authorization::RBAC::VERSION, Perl $], $^X" );
