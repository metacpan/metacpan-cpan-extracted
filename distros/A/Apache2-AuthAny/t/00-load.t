#!perl -T

use Test::More tests => 9;

BEGIN {
	use_ok( 'Apache2::AuthAny' );
	use_ok( 'Apache2::AuthAny::AuthenHandler' );
	use_ok( 'Apache2::AuthAny::AuthUtil' );
	use_ok( 'Apache2::AuthAny::AuthzHandler' );
	use_ok( 'Apache2::AuthAny::Cookie' );
	use_ok( 'Apache2::AuthAny::DB' );
	use_ok( 'Apache2::AuthAny::FixupHandler' );
	use_ok( 'Apache2::AuthAny::MapToStorageHandler' );
	use_ok( 'Apache2::AuthAny::RequestConfig' );
}

diag( "Testing Apache2::AuthAny $Apache2::AuthAny::VERSION, Perl $], $^X" );
