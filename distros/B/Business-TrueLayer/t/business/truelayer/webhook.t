#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use Mojo::JWT;
use Mojo::JSON;
use Crypt::OpenSSL::RSA;

use_ok( 'Business::TrueLayer::Webhook' );

# generate a JWT we can use for testing - we can't use anything from
# TrueLayer as we a) don't know their private key for signing the JWT,
# and b) can't be sure the the details from the jwks will not change

my $private_key = "-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDLy/mVwBQmT76UNIilJd+d3t0SxjMWDthb77WgfNZ2f3/TxhUH
re3Mr/AgNSTzXz8GQSuWwgY9HwiDcp6c6eHnQWY/mF0/ig3BDDHIWjySaFc09Kfb
V4sWpte5KhS3M+FTzMtbdfZtp48R0wp8HHnduKchlrh6Vt+fNCdlXCzBYwIDAQAB
AoGAL9eFkvMRh+Dmk3I1tddLRItiCJtAuOfpQMPoNnG4Av9xaayxmSjqj0eqLlVr
hDqS2AwKiIyp3EVhwUHyHFIHdtAp/DhLMNymA6cOYZ+pSIQyF+1e/Q7KsitKrQht
YHzjC8P7lWMK5nfzrSEz9ykRtqO0yRMUJ+E12I4O/xkgV4kCQQDq0qGaSHl/cYcI
ibQJEUbHGhOscsSg61MmbsSQt2pfMPo7oP1fPaYcysLRmbg+ZTx8YfDDMR6R+CDX
uVl2D6udAkEA3i0LXB8JolUBEoxle/e59X3SmjVqFNMp/ClA9NeRttyiMsesCOf6
OouEMBAiDAZKlgznFPfoyJYQOakdSQMQ/wJBANKrXWg5FSeNBoRWZjqsUT9W2ceg
v19PQC3+ukLLCpeULStJ54aGnHzAO8AnlPAFixpcE9BKRQ7X+T8Qfn442NECQEwT
roUf16OvacuZKZL2c8W9DOVjDu0MlZ7T3Xs5aZrtF9k9iAoQrR1o8p2mmJH3gYi5
6FLExQASaoHkB7Qdia8CQQCXHtxHmBiNR1CF6qTGjhCPChPidvmhXNtDShHM3Gi7
yY9KhOLcT4W0YyXCCoEjG0bzu4OtK5ukhic86BYvbfYV
-----END RSA PRIVATE KEY-----";

my $public_key = "-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAMvL+ZXAFCZPvpQ0iKUl353e3RLGMxYO2FvvtaB81nZ/f9PGFQet7cyv
8CA1JPNfPwZBK5bCBj0fCINynpzp4edBZj+YXT+KDcEMMchaPJJoVzT0p9tXixam
17kqFLcz4VPMy1t19m2njxHTCnwced24pyGWuHpW3580J2VcLMFjAgMBAAE=
-----END RSA PUBLIC KEY-----";

my $jwkset = [
	{
	"kty" => "RSA",
	"alg" => "RS512",
	"kid" => "3f1266344cc2e6c2d8ede78240de88",
	"n" => "y8v5lcAUJk--lDSIpSXfnd7dEsYzFg7YW--1oHzWdn9_08YVB63tzK_wIDUk818_BkErlsIGPR8Ig3KenOnh50FmP5hdP4oNwQwxyFo8kmhXNPSn21eLFqbXuSoUtzPhU8zLW3X2baePEdMKfBx53binIZa4elbfnzQnZVwswWM",
	"e" => "AQAB",
	}
];

my %payload = (
	algorithm => 'RS512',
	header => {
		kid => "3f1266344cc2e6c2d8ede78240de88",
		jku => 'https://webhooks.truelayer-sandbox.com/.well-known/jwks',
	},
	claims => {
		"type" => "mandate_authorized",
		"event_version" => 1,
		"authorized_at" => "2024-08-23T07:26:33Z"
	},
	secret => $private_key,
);

my $jwt = Mojo::JWT->new( %payload )->encode;

my $Webhook = Business::TrueLayer::Webhook->new({
	jwks => $jwkset,
	jwt  => $jwt,
});

isa_ok( $Webhook,'Business::TrueLayer::Webhook','with jwks' );

subtest 'no jwks provided' => sub {

	no warnings qw/ redefine once /;

	local *Mojo::UserAgent::get = sub { return $_[0] };
	local *Mojo::UserAgent::result = sub { return $_[0] };
	local *Mojo::UserAgent::json = sub { return { keys => $jwkset } };

	$Webhook = Business::TrueLayer::Webhook->new({ jwt => $jwt });
	isa_ok( $Webhook,'Business::TrueLayer::Webhook','without jwks' );

	cmp_deeply(
		$Webhook->_payload,
		{
			'authorized_at' => '2024-08-23T07:26:33Z',
			'event_version' => 1,
			'type' => 'mandate_authorized'
		},
		'->_payload'
	);

	subtest 'with unknown jku' => sub {

		$payload{header}{jku} = 'https://some.man.in.the.middle.com';
		$jwt = Mojo::JWT->new( %payload )->encode;

		throws_ok(
			sub { Business::TrueLayer::Webhook->new({ jwt => $jwt }) },
			qr/is not in the jku_accept_list/,
			'throws meaningful error'
		);
	};
};

subtest '_payload' => sub {

	# https://docs.truelayer.com/docs/mandate-webhooks
	$Webhook->_payload({
		'type' => 'mandate_authorized',
		'event_id' => 'SOMEUUID',
		'event_version' => 1,
		'mandate_id' => '123456',
		'authorized_at' => '2024-08-23T07:26:33Z',
		'metadata' => {},
	});

	ok( ! $Webhook->is_payment,'! ->is_payment' );
	ok( $Webhook->is_mandate,'->is_mandate' );

	subtest '->resource' => sub {
		isa_ok(
			my $Mandate = $Webhook->resource,
			'Business::TrueLayer::Webhook::Mandate'
		);
		is( $Mandate->id,'123456','->id' );
		is( $Mandate->status,'authorized','->status' );
		ok( $Mandate->authorized,'->authorized' );
	};
};

done_testing();
