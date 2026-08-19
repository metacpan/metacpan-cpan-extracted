#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Protocol::HAP::Controller: constructor, transport
# injection and error paths. The conformance tests in
# t/conformance/hap-pairing-exchange.t cover the full protocol
# exchanges.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

BEGIN {
	eval {
		require Math::BigInt;
		require Crypt::Ed25519;
		require Crypt::Curve25519;
		require Crypt::AuthEnc::ChaCha20Poly1305;
	};
	if ($@) {
		plan skip_all => 'Crypto dependencies not available';
	}
}

use_ok('Protocol::HAP::Controller');
use_ok('Protocol::HAP::SRP');
use_ok('Protocol::HAP::TLV');
use_ok('Protocol::HAP::Pairing');

# Constructor defaults and identity generation
{
	my $controller =
	    Protocol::HAP::Controller->new(
		controller_id => 'openhap-test-ctrl' );

	ok( defined $controller, 'controller created with defaults' );
	is( $controller->{host}, '127.0.0.1', 'default host' );
	is( $controller->{port}, 51827,       'default port' );
	ok( defined $controller->{ltsk}, 'controller LTSK generated' );
	is( length( $controller->{ltpk} ), 32, 'LTPK is 32 bytes' );
	ok( !$controller->is_encrypted, 'session starts unencrypted' );
	is( $controller->last_error, undef, 'no error initially' );

	# controller_id is required: it goes into the pair-setup
	# signature, so the library must not invent one
	my $ok = eval { Protocol::HAP::Controller->new; 1 };
	ok( !$ok, 'new without controller_id dies' );
	like( $@, qr/controller_id required/, 'and says why' );
}

# Transport injection: requests flow through the code ref
{
	my $seen;
	my $transport = sub ($request) {
		$seen = $request;
		return "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nhi";
	};
	my $controller =
	    Protocol::HAP::Controller->new(
	    transport     => $transport,
	    controller_id => 'openhap-test-ctrl',
	    );

	my $response = $controller->request( 'GET', '/accessories' );
	like( $seen, qr{^GET /accessories HTTP/1\.1\r\n},
		'request bytes passed to the transport' );
	is( $response->{status}, 200,  'status parsed' );
	is( $response->{body},   'hi', 'body parsed' );
	is( $response->{headers}{'content-length'},
		2, 'headers parsed and lowercased' );
}

# Connection refused: pair_setup fails and sets last_error
{
	my $controller = Protocol::HAP::Controller->new(
		host          => '127.0.0.1',
		port          => 1,               # nothing listens here
		timeout       => 1,
		controller_id => 'openhap-test-ctrl',
	);

	ok( !$controller->pair_setup, 'pair_setup fails without server' );
	ok( defined $controller->last_error, 'last_error set' );
	like( $controller->last_error, qr/connect|no response/,
		'error mentions the connection failure' );
}

# Malformed TLV response: the controller records the error and does
# not crash
{
	my $transport = sub ($request) {
		my $body = "\x06\xFF\x01";    # length past end of buffer
		return
		      "HTTP/1.1 200 OK\r\n"
		    . 'Content-Length: '
		    . length($body)
		    . "\r\n\r\n"
		    . $body;
	};
	my $controller =
	    Protocol::HAP::Controller->new(
	    transport     => $transport,
	    controller_id => 'openhap-test-ctrl',
	    );

	ok( !$controller->pair_setup, 'malformed TLV response fails' );
	ok( defined $controller->last_error, 'last_error set' );
}

# TLV error response: last_error exposes the error code
{
	my $transport = sub ($request) {
		my $body = Protocol::HAP::TLV::encode(
			Protocol::HAP::Pairing::kTLVType_State() => pack( 'C', 2 ),
			Protocol::HAP::Pairing::kTLVType_Error() => pack(
				'C', Protocol::HAP::Pairing::kTLVError_MaxTries()
			),
		);
		return
		      "HTTP/1.1 200 OK\r\n"
		    . 'Content-Length: '
		    . length($body)
		    . "\r\n\r\n"
		    . $body;
	};
	my $controller =
	    Protocol::HAP::Controller->new(
	    transport     => $transport,
	    controller_id => 'openhap-test-ctrl',
	    );

	ok( !$controller->pair_setup, 'error TLV fails the exchange' );
	is( $controller->last_error,
		Protocol::HAP::Pairing::kTLVError_MaxTries(),
		'TLV error code exposed through last_error' );
}

# Non-200 HTTP status is an error
{
	my $transport = sub ($request) {
		return "HTTP/1.1 470 Connection Authorization Required\r\n"
		    . "Content-Length: 0\r\n\r\n";
	};
	my $controller =
	    Protocol::HAP::Controller->new(
	    transport     => $transport,
	    controller_id => 'openhap-test-ctrl',
	    );

	ok( !$controller->pair_setup, 'non-200 status fails' );
	is( $controller->last_error, 'HTTP 470', 'status in last_error' );
}

# Client SRP dies on out-of-order calls
{
	my $srp =
	    Protocol::HAP::SRP::Client->new( password => '123-45-678' );

	eval { $srp->compute_proof( 'salt', 'B' ) };
	like( $@, qr/compute_public not called/,
		'compute_proof before compute_public dies' );

	eval { $srp->verify_server_proof('M2') };
	like( $@, qr/compute_proof not called/,
		'verify_server_proof before compute_proof dies' );
}

# Client SRP rejects a bogus server public key
{
	my $srp =
	    Protocol::HAP::SRP::Client->new( password => '123-45-678' );
	$srp->compute_public;

	my $M1 = $srp->compute_proof( 'x' x 16, "\x00" x 384 );
	ok( !defined $M1, 'B mod N == 0 rejected' );
}

done_testing();
