#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Serializer::CBOR' );
}

diag( "Testing Dancer-Serializer-CBOR $Dancer::Serializer::CBOR::VERSION, Perl $], $^X" );
