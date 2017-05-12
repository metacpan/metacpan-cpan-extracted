#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CryoTel::CryoCon' );
}

diag( "Testing CryoTel::CryoCon $CryoTel::CryoCon::VERSION, Perl $], $^X" );
