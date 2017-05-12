#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Crypt::Util;

my ( $c, $fallback_digest, $fallback_mac );

BEGIN {
	$c = Crypt::Util->new;

	$fallback_digest = eval { $c->fallback_digest };
	plan skip_all => "Couldn't load any digest" if $@;

	$fallback_mac = eval { $c->fallback_mac };
	plan skip_all => "Couldn't load any mac" if $@;

	plan 'no_plan';
}

my $string = "magic moose";

my $hash = $c->digest_string( string => $string );

ok(
	eval {
		$c->verify_hash(
			hash   => $hash,
			string => $string,
		);
	},
	"verify digest",
);

ok( !$@, "no error" ) || diag $@;

ok(
	eval {
		!$c->verify_hash(
			hash   => $hash,
			string => "some other string",
		);
	},
	"verify bad digest",
);

ok( !$@, "no error" ) || diag $@;

throws_ok {
	$c->verify_hash(
		hash   => $hash,
		string => "some other string",
		fatal  => 1,
	),
} qr/verification failed/, "verify_hash with fatal => 1";

{
	my $mac_1 = $c->mac_digest_string( string => "foo", key => "moose" );
	my $mac_2 = $c->mac_digest_string( string => "foo", key => "elk" );

	cmp_ok( $mac_1, "ne", $mac_2, "mac hashes are ne with different keys" );
}

{
	my $mac_1 = $c->mac_digest_string( string => "foo", key => "moose" );
	my $mac_2 = $c->mac_digest_string( string => "bar", key => "moose" );

	cmp_ok( $mac_1, "ne", $mac_2, "mac hashes are ne with different messages" );
}

{
	my $mac_1 = $c->mac_digest_string( string => "foo", key => "moose" );
	my $mac_2 = $c->mac_digest_string( string => "foo", key => "moose" );

	is( $mac_1, $mac_2, "mac hashes are eq when the same" );
}


SKIP: {
	eval { require Digest::MD5 };
	skip "Digest::MD5 couldn't be loaded", 3 if $@;
	skip "Digest::MD5 is the only fallback", 3 if $fallback_digest eq "SHAMD5";

	my $md5_hash = $c->digest_string(
		digest => "MD5",
		string => $string,
	);

	cmp_ok( $md5_hash, "ne", $hash, "$fallback_digest hash ne MD5 hash" );

	ok(
		!$c->verify_hash(
			hash   => $md5_hash,
			string => $string,
		),
		"verification fails without same digest",
	);

	ok(
		$c->verify_hash(
			hash   => $md5_hash,
			string => $string,
			digest => "MD5",
		),
		"verification succeeds when MD5",
	);
}

