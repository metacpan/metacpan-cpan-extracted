#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Authentication::Store::LDAP::AD::Class' ) || print "Bail out!
";
}

diag( "Testing Catalyst::Authentication::Store::LDAP::AD::Class $Catalyst::Authentication::Store::LDAP::AD::Class::VERSION, Perl $], $^X" );
