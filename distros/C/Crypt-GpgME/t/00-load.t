#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Crypt::GpgME' );
}

diag( "Testing Crypt::GpgME $Crypt::GpgME::VERSION, Perl $], $^X on gpgme " . Crypt::GpgME->GPGME_VERSION );
