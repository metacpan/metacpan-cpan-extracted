#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DJabberd::Authen::LDAP' );
}

diag( "Testing DJabberd::Authen::LDAP $DJabberd::Authen::LDAP::VERSION, Perl $], $^X" );
