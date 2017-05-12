#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Crypt::Util;

my $c;

BEGIN {
	$c = Crypt::Util->new;

	eval { $c->fallback_digest; $c->fallback_cipher; $c->fallback_mac; $c->fallback_authenticated_mode };
	plan skip_all => "$1" if $@ =~ /(Couldn't load any \w+)/;
	plan skip_all => "Couldn't load fallback" if $@;

	plan 'no_plan';
}

$c->default_key("foo");

foreach my $encrypted ( 1, 0 ) { # encrypted not yet supported

	foreach my $data (
		"zemoose gauhy tj lkj GAJE E djjjj laaaa di da dooo",
		{ foo => "bar", gorch => [ qw/very deep/, 1 .. 10 ] },
		"\0 bar evil binary string \0 \0\0 foo la \xff foo \0 bar",
	) {

		my $tamper;

		lives_ok { $tamper = $c->tamper_proof( data => $data, encrypt => $encrypted ) } "tamper proofing lived (" . ($encrypted ? "aead" : "mac signed") .")";

		ok( defined($tamper), "got some output" );

		unless ( ref $data ) {
			if ( $encrypted ) {
				unlike( $tamper, qr/\Q$data/, "tamper proof does not contain the original" )
			} else {
				like( $tamper, qr/\Q$data/, "tamper proof contains the original" )
			}
		}

		my $thawed;

		lives_ok { $thawed = $c->thaw_tamper_proof( string => $tamper ) } "tamper proof thaw lived";

		ok( defined($thawed), "got some output" );

		is_deeply( $thawed, $data, "tamper resistence round trips (" . ($encrypted ? "aead" : "mac signed") .")" );

		my $corrupt_tamper = $tamper;
		substr( $corrupt_tamper, -10, 5 ) ^= "moose";

		throws_ok {
			$c->thaw_tamper_proof( string => $corrupt_tamper );
		} qr/verification.*failed/i, "corrupt tamper proof string failed";


		my $twaddled_tamper;
		if ( $encrypted ) {
			my ( $type, $inner ) = $c->_unpack_tamper_proof($tamper);
			$twaddled_tamper = $c->decrypt_string( string => $inner );
			substr( $twaddled_tamper, -10, 5 ) ^= "moose";
			$twaddled_tamper = $c->_pack_tamper_proof($type, $c->encrypt_string( string => $twaddled_tamper ));
		} else {
			$twaddled_tamper = $tamper;
			substr( $twaddled_tamper, -10, 5 ) ^= "moose";
		}

		throws_ok {
			$c->thaw_tamper_proof( string => $twaddled_tamper );
		} qr/verification.*failed/i, "altered tamper proof string failed";

		local $Crypt::Util::PACK_FORMAT_VERSION = 2;

		throws_ok {
			$c->thaw_tamper_proof( string => $tamper );
		} qr/Incompatible packed string/, "version check";
	}

}
