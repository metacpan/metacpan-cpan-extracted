#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Crypt::Util";

my $c = Crypt::Util->new;

my @strings = (
	'moose',
	'foo bar gorch',
	"\x00 \xff thzxgtj j\$/..,.,\"at {}\$2 1 \n \r \t",
	# test various paddings
	' ',
	'   ',
	'    ',
	'     ',
	'       ',
);

SKIP: {
	skip "URI::Escape required", @strings * 3 unless eval { require URI::Escape };
	skip "MIME::Base64 required", @strings * 3 unless eval { require MIME::Base64 };
	skip "MIME::Base64::URLSafe required", @strings * 3 unless eval { require MIME::Base64::URLSafe };

	foreach my $string ( @strings ) { 
		my $encoded = $c->encode_string_uri_base64( $string );
		my $double_encoded = $c->encode_string_uri_escape( $encoded );

		like( $encoded, qr/^[\w\*\-]+$/, "only valid chars" );
		is( $encoded, $double_encoded, "no need for further URI escaping" );

		is( $c->decode_string_uri_base64($encoded), $string, "round trip" );
	}
}

SKIP: foreach my $encoding (qw/hex uri_escape base64 base32 uri_base64/) {
	skip "couldn't load $encoding provider", @strings * 2 unless $c->_try_encoding_fallback($encoding);	

	foreach my $string  ( @strings ) {
		ok( defined( my $encoded = $c->encode_string( encoding => $encoding, string => $string ) ), "encode with $encoding" );
		is( $c->decode_string( encoding => $encoding, string => $encoded ), $string, "$encoding round trip" );
	}
}

foreach my $encoding (qw/uri alphanumerical printable/) {
	foreach my $string  ( @strings ) {
		ok( defined( my $encoded = $c->encode_string( encoding => $encoding, string => $string ) ), "encode with $encoding" );
		is( $c->decode_string( encoding => $encoding, string => $encoded ), $string, "$encoding round trip" );
	}
}
