#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DJabberd::Plugin::VCard::LDAP' );
}

diag( "Testing DJabberd::Plugin::VCard::LDAP $DJabberd::Plugin::VCard::LDAP::VERSION, Perl $], $^X" );
