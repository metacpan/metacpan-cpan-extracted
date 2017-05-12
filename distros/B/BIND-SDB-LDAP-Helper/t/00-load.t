#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'BIND::SDB::LDAP::Helper' );
}

diag( "Testing BIND::SDB::LDAP::Helper $BIND::SDB::LDAP::Helper::VERSION, Perl $], $^X" );
