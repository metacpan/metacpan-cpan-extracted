#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Crypt::Util";

can_ok "Crypt::Util" => qw/
	cipher_object
	digest_object
/;

my $c = Crypt::Util->new;

isa_ok( $c, "Crypt::Util" );

ok( !$c->has_default_cipher, "no default cipher" );

SKIP: {
	my $fallback_cipher = eval { $c->fallback_cipher };

	skip "Couldn't load any cipher", 8 unless $fallback_cipher;
	skip "Couldn't load any mode", 8 unless eval { $c->fallback_mode };

	ok( defined($fallback_cipher), "fallback defined" );

	my $cipher = $c->cipher_object( key => "foo" );

	can_ok( $cipher, qw/encrypt decrypt/ );
	my $ciphertext = $cipher->encrypt("foo");
	$cipher->reset if $cipher->can("reset");
	is( $cipher->decrypt($ciphertext), "foo", "round trip encryption" );

	$c->default_key("moose");

	my ( $binary, $encoded ) = map { $c->encrypt_string(
		string => "The quick brown fox had a crush on the lazy moose. One day she wrote the moose a love letter but since he was lazy he never replied. The end.",
		encode => $_,
	) } 0, 1;

	like(
		$encoded,
		qr{^[\w\+\*\-/=]+$},
		"no funny chars",
	);

	cmp_ok( $binary, "ne", $encoded, "encoded != binary" );

	cmp_ok( length($binary), "<", length($encoded), "encoded is longer" );

	is( $c->decrypt_string( string => $encoded, decode => 1 ), $c->decrypt_string( string => $binary ), "decoded == binary" );
}

ok( !$c->has_default_digest, "no default digest" );

my $fallback_digest = eval { $c->fallback_digest };

SKIP: {
	skip "Couldn't load any digest", 4 if $@ =~ /^Couldn't load any digest/;

	ok( !$@, "no unexpected error" );
	ok( defined($fallback_digest), "fallback defined" );

	my $digest = $c->digest_object;

	can_ok( $digest, qw/add digest/ );

	$digest->add("foo");

	my $foo_digest = $digest->digest;

	$digest->add("bar");

	my $bar_digest = $digest->digest;

	cmp_ok( $foo_digest, "ne", $bar_digest, "digests differ" );

}


