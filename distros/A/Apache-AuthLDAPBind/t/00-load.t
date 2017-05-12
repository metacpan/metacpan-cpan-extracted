#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache::AuthLDAPBind' );
}

diag( "Testing Apache::AuthLDAPBind $Apache::AuthLDAPBind::VERSION, Perl $], $^X" );
