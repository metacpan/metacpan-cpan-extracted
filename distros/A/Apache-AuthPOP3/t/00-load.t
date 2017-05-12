#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache::AuthPOP3' );
}

diag( "Testing Apache::AuthPOP3 $Apache::AuthPOP3::VERSION, Perl $], $^X" );
