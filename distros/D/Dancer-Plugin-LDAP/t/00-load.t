#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::LDAP' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::LDAP $Dancer::Plugin::LDAP::VERSION, Perl $], $^X" );
