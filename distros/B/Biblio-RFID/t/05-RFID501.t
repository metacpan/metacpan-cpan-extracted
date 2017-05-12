#!/usr/bin/perl

use Test::More tests => 8;
use Data::Dump qw(dump);

use lib 'lib';

BEGIN {
	use_ok( 'Biblio::RFID::RFID501' );
}

my $tags =
[ [
	"\4\21\0\0",
	2009,
	"0101",
	"0123",
	"\0\0\0\0",
	"\xFF\xFF\xFF\xFF",
	"\x7F\xFF\xFF\xFF",
	"\0\0\0\0",
],[
	"\4\21\0\1",
	1302,
	"0037",
	"67\0\0",
	"\0\0\0\0",
	"\0\0\0\0",
	"\0\0\0\0",
	"\0\0\0\0",
] ];

foreach my $tag ( @$tags ) {

	ok( $hash = Biblio::RFID::RFID501->to_hash( $tag ), 'to_hash' );
	diag dump $hash;

	ok( $bytes = Biblio::RFID::RFID501->from_hash( $hash ), 'from_hash' );
	my $orig = join('', @$tag);
	cmp_ok( $bytes, 'eq', $orig, 'roundtrip' );

	diag dump( $orig, $bytes );

}

ok( my $bytes = Biblio::RFID::RFID501->blank, 'blank' );
diag dump $bytes;

