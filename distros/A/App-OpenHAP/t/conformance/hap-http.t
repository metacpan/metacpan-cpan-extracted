#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/HAP-HTTP.md
#
# The tests drive the sans-IO Protocol::HAP::Server engine through its
# public API - session_open, receive, and a captured output contract -
# without sockets. The tests set the session's verified state directly
# to model the paired and unpaired cases.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;
use JSON::PP ();

BEGIN {
	eval {
		require Crypt::Ed25519;
		require Crypt::AuthEnc::ChaCha20Poly1305;
	};
	if ($@) {
		plan skip_all => 'Required modules not available';
	}
}

use_ok('Protocol::HAP::Server');
use_ok('Protocol::HAP::Store::Memory');
use_ok('Protocol::HAP::HTTP');
use_ok('Protocol::HAP::Crypto');
use_ok('Protocol::HAP::TLV');
use_ok('Protocol::HAP::Pairing');
use_ok('App::OpenHAP::TestMock::MQTT');
use_ok('App::OpenHAP::Tasmota::Heater');

my $json = JSON::PP->new;

# Everything the engine writes, keyed by session id. This is the
# output contract: the host files the bytes under the connection the
# session belongs to.
my %OUT;

sub make_hap ()
{
	my $hap = Protocol::HAP::Server->new(
		pin    => '123-45-678',
		name   => 'Conformance Bridge',
		store  => Protocol::HAP::Store::Memory->new,
		output => sub ( $session, $bytes ) {
			$OUT{ $session->id } .= $bytes;
		},
	);
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Test Heater',
		mqtt_topic  => 'heater',
		mqtt_client => $mqtt,
	);
	$hap->add_accessory($heater);
	return $hap;
}

sub verified_session ( $hap, $controller_id = 'test-controller' )
{
	my $session = $hap->session_open;
	$session->set_verified($controller_id);
	return $session;
}

# The controller half of the encrypted session framing, for the tests
# that subscribe to events. The accessory encrypts with one key and
# decrypts with the other; the client counters run independently of
# the session's.
my $ACC_TO_CTRL = pack( 'H*', '11' x 32 );
my $CTRL_TO_ACC = pack( 'H*', '22' x 32 );
my %CLIENT;

sub client_state ($session)
{
	return $CLIENT{ $session->id } //= { enc => 0, dec => 0 };
}

sub client_encrypt ( $session, $data )
{
	my $state = client_state($session);
	my $out   = '';
	while ( length($data) > 0 ) {
		my $chunk = substr( $data, 0, 1024, '' );
		my $aad   = pack( 'v',      length($chunk) );
		my $nonce = pack( 'x[4]Q<', $state->{enc}++ );
		my ( $ciphertext, $tag ) =
		    Protocol::HAP::Crypto->chacha20poly1305_encrypt(
			$CTRL_TO_ACC, $nonce, $chunk, $aad );
		$out .= $aad . $ciphertext . $tag;
	}
	return $out;
}

sub client_decrypt ( $session, $data )
{
	my $state = client_state($session);
	my $out   = '';
	my $pos   = 0;
	while ( $pos < length($data) ) {
		my $length = unpack( 'v', substr( $data, $pos, 2 ) );
		my $aad    = substr( $data, $pos, 2 );
		$pos += 2;
		my $ciphertext = substr( $data, $pos, $length );
		$pos += $length;
		my $tag = substr( $data, $pos, 16 );
		$pos += 16;

		my $nonce = pack( 'x[4]Q<', $state->{dec}++ );
		my $plain =
		    Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$ACC_TO_CTRL, $nonce, $ciphertext, $tag, $aad );
		return unless defined $plain;
		$out .= $plain;
	}
	return $out;
}

sub dispatch ( $hap, $method, $path, $body = undef, $session = undef )
{
	$session //= verified_session($hap);

	my $raw = Protocol::HAP::HTTP::build_request(
		method => $method,
		path   => $path,
		body   => $body // '',
	);
	$raw = client_encrypt( $session, $raw ) if $session->is_encrypted;

	$OUT{ $session->id } = '';
	$hap->receive( $session, $raw );
	my $response = delete $OUT{ $session->id };
	$response = client_decrypt( $session, $response )
	    if $session->is_encrypted;

	my ( $head, $resp_body ) = split /\r\n\r\n/, $response, 2;
	my ($status) = $head =~ m{^HTTP/1\.1 (\d+)};
	my %headers;
	for my $line ( split /\r\n/, $head ) {
		$headers{ lc $1 } = $2 if $line =~ /^([^:]+):\s*(.*)$/;
	}
	return ( $status, \%headers, $resp_body // '' );
}

# Find the aid/iid of a characteristic by short type in /accessories
sub find_char ( $accessories, $type )
{
	for my $acc ( @{ $accessories->{accessories} } ) {
		for my $svc ( @{ $acc->{services} } ) {
			for my $char ( @{ $svc->{characteristics} } ) {
				return ( $acc->{aid}, $char->{iid} )
				    if $char->{type} eq $type;
			}
		}
	}
	return;
}

subtest '[HAP-HTTP §1] endpoints require a verified session' => sub {
	my $hap        = make_hap();
	my $unverified = $hap->session_open;

	for my $probe (
		[ 'POST', '/pairings' ],
		[ 'GET',  '/accessories' ],
		[ 'GET',  '/characteristics?id=1.1' ],
		[ 'PUT',  '/characteristics' ],
		[ 'PUT',  '/prepare' ],
	    )
	{
		my ( $status, undef, undef ) =
		    dispatch( $hap, @$probe, undef, $unverified );
		is( $status, 470,
			"[HAP-HTTP §13.4] @$probe returns 470 "
			    . 'without pair-verify' );
	}

	# Pairing endpoints do not need a verified session
	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	my ( $status, undef, undef ) =
	    dispatch( $hap, 'POST', '/pair-setup', $m1, $unverified );
	is( $status, 200,
		'[HAP-HTTP §4] POST /pair-setup open to unverified sessions'
	);

	# Pair-verify is also open and answers with TLV
	my $pv_m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),     pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_PublicKey(), 'X' x 32,
	);
	( $status, my $headers, undef ) =
	    dispatch( $hap, 'POST', '/pair-verify', $pv_m1, $unverified );
	is( $status, 200,
		'[HAP-HTTP §5] POST /pair-verify open to unverified sessions'
	);
};

subtest '[HAP-HTTP §2] content types' => sub {
	my $hap = make_hap();

	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	my ( undef, $headers, undef ) =
	    dispatch( $hap, 'POST', '/pair-setup', $m1,
		$hap->session_open );
	is( $headers->{'content-type'},
		'application/pairing+tlv8',
		'pairing endpoints use application/pairing+tlv8' );

	( undef, $headers, undef ) = dispatch( $hap, 'GET', '/accessories' );
	is( $headers->{'content-type'},
		'application/hap+json',
		'accessory endpoints use application/hap+json' );
};

subtest '[HAP-HTTP §3] POST /identify paired vs unpaired' => sub {
	my $hap = make_hap();
	my $unverified = $hap->session_open;

	my ( $status, undef, undef ) =
	    dispatch( $hap, 'POST', '/identify', undef, $unverified );
	is( $status, 204, 'unpaired identify returns 204 No Content' );

	$hap->{store}->save_pairing( 'controller', 'X' x 32, 1 );
	( $status, undef, my $body ) =
	    dispatch( $hap, 'POST', '/identify', undef, $unverified );
	is( $status, 400, 'paired identify returns 400' );
	is( $json->decode($body)->{status},
		-70401, 'paired identify body is {"status":-70401}' );
};

subtest '[HAP-HTTP §7] GET /accessories structure' => sub {
	my $hap = make_hap();
	my ( $status, undef, $body ) =
	    dispatch( $hap, 'GET', '/accessories' );

	is( $status, 200, 'returns 200 with body' );
	my $data = $json->decode($body);
	ok( ref $data->{accessories} eq 'ARRAY', 'accessories array' );

	my ($bridge) = grep { $_->{aid} == 1 } @{ $data->{accessories} };
	ok( $bridge, 'bridge accessory has aid 1' );

	my ($heater) = grep { $_->{aid} == 2 } @{ $data->{accessories} };
	ok( $heater, '[HAP-HTTP §7.1] accessory object has aid and services' );
	ok( ref $heater->{services} eq 'ARRAY',
		'[HAP-HTTP §7.1] services is an array' );
	for my $svc ( @{ $heater->{services} } ) {
		ok( defined $svc->{iid},
			'[HAP-HTTP §7.2] service object has iid' );
		ok( defined $svc->{type},
			'[HAP-HTTP §7.2] service object has type' );
		ok( ref $svc->{characteristics} eq 'ARRAY',
			'[HAP-HTTP §7.2] service has characteristics array' );
	}

	# [HAP-HTTP §7.3] characteristic objects carry type, iid, perms,
	# format, and value for readable characteristics
	my ($char) =
	    grep { $_->{type} eq '25' }
	    map  { @{ $_->{characteristics} } } @{ $heater->{services} };
	ok( $char, 'found On characteristic object' );
	ok( defined $char->{iid},
		'[HAP-HTTP §7.3] characteristic has iid' );
	ok( defined $char->{format},
		'[HAP-HTTP §7.3] characteristic has format' );
	ok( ref $char->{perms} eq 'ARRAY',
		'[HAP-HTTP §7.3] characteristic has perms' );
	ok( exists $char->{value},
		'[HAP-HTTP §7.3] readable characteristic has value' );
};

subtest '[HAP-HTTP §8] GET /characteristics' => sub {
	my $hap = make_hap();
	my ( undef, undef, $acc_body ) =
	    dispatch( $hap, 'GET', '/accessories' );
	my ( $aid, $iid ) = find_char( $json->decode($acc_body), '25' );
	ok( defined $iid, 'found On characteristic' );

	my ( $status, undef, $body ) =
	    dispatch( $hap, 'GET', "/characteristics?id=$aid.$iid" );
	is( $status, 200,
		'[HAP-HTTP §13.1][HAP-HTTP §16.1] valid read returns 200' );
	my $data = $json->decode($body);
	is( $data->{characteristics}[0]{aid}, $aid, 'response has aid' );
	is( $data->{characteristics}[0]{iid}, $iid, 'response has iid' );
	ok( exists $data->{characteristics}[0]{value},
		'[HAP-HTTP §16.1] response carries the value' );

	# The meta/perms/type parameters include the optional fields
	( $status, undef, $body ) = dispatch( $hap, 'GET',
		"/characteristics?id=$aid.$iid&meta=1&perms=1&type=1" );
	$data = $json->decode($body);
	ok( exists $data->{characteristics}[0]{format},
		'meta=1 includes format' );
	ok( exists $data->{characteristics}[0]{perms},
		'perms=1 includes permissions' );
	ok( exists $data->{characteristics}[0]{type},
		'type=1 includes type' );

	# [HAP-HTTP §12] invalid aid.iid -> -70409, [HAP-HTTP §9] 207
	( $status, undef, $body ) =
	    dispatch( $hap, 'GET', "/characteristics?id=999.999" );
	is( $status, 207, 'invalid id returns 207 Multi-Status' );
	is( $json->decode($body)->{characteristics}[0]{status},
		-70409, 'invalid id has status -70409' );
};

subtest '[HAP-HTTP §9] PUT /characteristics' => sub {
	my $hap = make_hap();
	my ( undef, undef, $acc_body ) =
	    dispatch( $hap, 'GET', '/accessories' );
	my ( $aid, $iid ) = find_char( $json->decode($acc_body), '25' );

	# A successful write returns 204 No Content
	my $put = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $iid, value => 1 } ] } );
	my ( $status, undef, $body ) =
	    dispatch( $hap, 'PUT', '/characteristics', $put );
	is( $status, 204,
		'[HAP-HTTP §13.1][HAP-HTTP §16.2] successful write '
		    . 'returns 204 No Content' );
	is( $body, '', '204 response has no body' );

	# Write to nonexistent characteristic: 207 with -70409
	$put = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => 9999, value => 1 } ] } );
	( $status, undef, $body ) =
	    dispatch( $hap, 'PUT', '/characteristics', $put );
	is( $status, 207, 'partial failure returns 207 Multi-Status' );
	is( $json->decode($body)->{characteristics}[0]{status},
		-70409, 'unknown iid has status -70409' );

	# Write to a read-only characteristic: -70404
	my ( undef, $ro_iid ) = find_char( $json->decode($acc_body), '30' );
	$put = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $ro_iid, value => 'x' } ] } );
	( $status, undef, $body ) =
	    dispatch( $hap, 'PUT', '/characteristics', $put );
	is( $status, 207, 'read-only write returns 207' );
	is( $json->decode($body)->{characteristics}[0]{status},
		-70404, 'read-only write has status -70404' );

	# [HAP-HTTP §13.2] malformed JSON returns 400
	( $status, undef, undef ) =
	    dispatch( $hap, 'PUT', '/characteristics', 'not json' );
	is( $status, 400, 'malformed body returns 400 Bad Request' );
};

subtest '[HAP-HTTP §10] PUT /prepare timed write' => sub {
	my $hap = make_hap();
	my $session = verified_session($hap);

	my $prepare = $json->encode( { ttl => 2500, pid => 11122333 } );
	my ( $status, undef, $body ) =
	    dispatch( $hap, 'PUT', '/prepare', $prepare, $session );
	is( $status, 200, 'prepare returns 200' );
	is( $json->decode($body)->{status}, 0, 'prepare status 0' );

	# Missing ttl/pid -> -70410 invalid value
	( $status, undef, $body ) =
	    dispatch( $hap, 'PUT', '/prepare', '{}', $session );
	is( $status, 400, 'missing ttl/pid rejected' );
	is( $json->decode($body)->{status},
		-70410, 'missing ttl/pid has status -70410' );

	# The server also accepts POST. The spec shows POST in the
	# endpoint table.
	( $status, undef, undef ) =
	    dispatch( $hap, 'POST', '/prepare', $prepare, $session );
	is( $status, 200, 'POST /prepare also accepted' );
};

subtest '[HAP-HTTP §6][HAP-Pairing §7][HAP-Pairing §7.1] add pairing' =>
    sub {
	my $hap = make_hap();
	$hap->{store}->save_pairing( 'admin-ctrl', 'A' x 32, 1 );
	$hap->{store}->save_pairing( 'user-ctrl',  'U' x 32, 0 );

	my $add = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),      pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(),     pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_Identifier(), 'new-ctrl',
		Protocol::HAP::Pairing::kTLVType_PublicKey(),  'N' x 32,
		Protocol::HAP::Pairing::kTLVType_Permissions(), pack( 'C', 0 ),
	);

	# Non-admin controller -> 0x02 Authentication
	my ( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$add, verified_session( $hap, 'user-ctrl' ) );
	my %tlv = Protocol::HAP::TLV::decode($body);
	is( unpack( 'C', $tlv{ Protocol::HAP::Pairing::kTLVType_Error() } ),
		Protocol::HAP::Pairing::kTLVError_Authentication(),
		'[HAP-Pairing §7.4] non-admin add rejected with 0x02' );

	# Admin controller -> success M2
	( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$add, verified_session( $hap, 'admin-ctrl' ) );
	%tlv = Protocol::HAP::TLV::decode($body);
	is( unpack( 'C', $tlv{ Protocol::HAP::Pairing::kTLVType_State() } ),
		2, 'admin add returns M2' );
	ok( !exists $tlv{ Protocol::HAP::Pairing::kTLVType_Error() },
		'admin add succeeds' );
	ok( exists $hap->{store}->load_pairings()->{'new-ctrl'},
		'pairing stored' );

	# Same identifier, different LTPK -> 0x01 Unknown
	my $conflict = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),      pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(),     pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_Identifier(), 'new-ctrl',
		Protocol::HAP::Pairing::kTLVType_PublicKey(),  'Z' x 32,
		Protocol::HAP::Pairing::kTLVType_Permissions(), pack( 'C', 1 ),
	);
	( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$conflict, verified_session( $hap, 'admin-ctrl' ) );
	%tlv = Protocol::HAP::TLV::decode($body);
	is( unpack( 'C', $tlv{ Protocol::HAP::Pairing::kTLVType_Error() } ),
		Protocol::HAP::Pairing::kTLVError_Unknown(),
		'[HAP-Pairing §7.4] existing identifier with different '
		    . 'LTPK rejected with 0x01' );

	# Same identifier, same LTPK -> permissions updated, success
	my $update = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),      pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(),     pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_Identifier(), 'new-ctrl',
		Protocol::HAP::Pairing::kTLVType_PublicKey(),  'N' x 32,
		Protocol::HAP::Pairing::kTLVType_Permissions(), pack( 'C', 1 ),
	);
	( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$update, verified_session( $hap, 'admin-ctrl' ) );
	%tlv = Protocol::HAP::TLV::decode($body);
	ok( !exists $tlv{ Protocol::HAP::Pairing::kTLVType_Error() },
		'matching LTPK updates permissions' );
	is( $hap->{store}->load_pairings()->{'new-ctrl'}{permissions},
		1, '[HAP-Pairing §6.1] permissions updated to admin (0x01)' );
};

subtest '[HAP-Pairing §7.2][HAP-Pairing §7.3] remove and list' => sub {
	my $hap = make_hap();
	$hap->{store}->save_pairing( 'admin-ctrl', 'A' x 32, 1 );
	$hap->{store}->save_pairing( 'user-ctrl',  'U' x 32, 0 );

	# List pairings (admin only)
	my $list = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 5 ),
	);
	my ( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$list, verified_session( $hap, 'user-ctrl' ) );
	my %tlv = Protocol::HAP::TLV::decode($body);
	is( unpack( 'C', $tlv{ Protocol::HAP::Pairing::kTLVType_Error() } ),
		Protocol::HAP::Pairing::kTLVError_Authentication(),
		'[HAP-Pairing §7.4] non-admin list rejected with 0x02' );

	( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$list, verified_session( $hap, 'admin-ctrl' ) );
	like( $body, qr/admin-ctrl/, 'list contains admin identifier' );
	like( $body, qr/user-ctrl/,  'list contains user identifier' );
	like( $body, qr/\xFF\x00/,
		'entries separated by zero-length 0xFF separator' );

	# The removal of a pairing that does not exist returns success
	my $remove_ghost = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),      pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(),     pack( 'C', 4 ),
		Protocol::HAP::Pairing::kTLVType_Identifier(), 'ghost-ctrl',
	);
	( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$remove_ghost, verified_session( $hap, 'admin-ctrl' ) );
	%tlv = Protocol::HAP::TLV::decode($body);
	ok( !exists $tlv{ Protocol::HAP::Pairing::kTLVType_Error() },
		'removing nonexistent pairing returns success' );

	# The removal of the last admin clears all pairings
	my $remove_admin = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),      pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(),     pack( 'C', 4 ),
		Protocol::HAP::Pairing::kTLVType_Identifier(), 'admin-ctrl',
	);
	( $status, undef, $body ) = dispatch( $hap, 'POST', '/pairings',
		$remove_admin, verified_session( $hap, 'admin-ctrl' ) );
	%tlv = Protocol::HAP::TLV::decode($body);
	ok( !exists $tlv{ Protocol::HAP::Pairing::kTLVType_Error() },
		'removing last admin succeeds' );
	is( scalar keys %{ $hap->{store}->load_pairings() },
		0, 'all pairings removed with the last admin' );
};

subtest '[HAP-HTTP §13][HAP-HTTP §13.2] unknown endpoint returns 404' =>
    sub {
	my $hap = make_hap();
	my ( $status, undef, undef ) =
	    dispatch( $hap, 'GET', '/no-such-endpoint' );
	is( $status, 404, 'unknown endpoint returns 404' );
};

subtest '[HAP-HTTP §15][HAP-HTTP §15.1] JSON value encoding' => sub {
	my $hap = make_hap();
	my ( undef, undef, $acc_body ) =
	    dispatch( $hap, 'GET', '/accessories' );
	my ( $aid, $iid ) = find_char( $json->decode($acc_body), '25' );

	# A bool encodes as JSON true/false, not 1/0
	my ( undef, undef, $body ) =
	    dispatch( $hap, 'GET', "/characteristics?id=$aid.$iid" );
	like( $body, qr/"value"\s*:\s*(?:true|false)/,
		'bool value encodes as JSON boolean' );

	my $put = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $iid, value => 1 } ] } );
	dispatch( $hap, 'PUT', '/characteristics', $put );
	( undef, undef, $body ) =
	    dispatch( $hap, 'GET', "/characteristics?id=$aid.$iid" );
	like( $body, qr/"value"\s*:\s*true/, 'true after write of 1' );

	# The string characteristics encode as JSON strings
	my ( undef, $name_iid ) = find_char( $json->decode($acc_body), '23' );
	( undef, undef, $body ) =
	    dispatch( $hap, 'GET', "/characteristics?id=$aid.$name_iid" );
	like( $body, qr/"value"\s*:\s*"/, 'string value encodes as string' );
};

subtest '[HAP-HTTP §15.2] type coercion on write' => sub {
	my $hap = make_hap();
	my ( undef, undef, $acc_body ) =
	    dispatch( $hap, 'GET', '/accessories' );
	my ( $aid, $iid ) = find_char( $json->decode($acc_body), '25' );

	# JSON true and numeric 1 both write a bool characteristic
	for my $value ( \1, 1 ) {
		my $put = $json->encode( { characteristics =>
			    [ { aid => $aid, iid => $iid,
				    value => $value } ] } );
		my ( $status, undef, undef ) =
		    dispatch( $hap, 'PUT', '/characteristics', $put );
		is( $status, 204, 'bool write coerced and accepted' );
	}
};

subtest '[HAP-HTTP §16][HAP-HTTP §16.3] event subscription via ev:true' =>
    sub {
	my $hap = make_hap();
	my ( undef, undef, $acc_body ) =
	    dispatch( $hap, 'GET', '/accessories' );
	my ( $aid, $iid ) = find_char( $json->decode($acc_body), '25' );

	my $session = verified_session($hap);
	my $put     = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $iid, ev => \1 } ] } );
	my ( $status, undef, undef ) =
	    dispatch( $hap, 'PUT', '/characteristics', $put, $session );
	is( $status, 204, 'subscription write returns 204' );
	ok( exists $hap->{event_subscriptions}{"$aid.$iid"}{ $session->id },
		'session registered for events' );

	# ev on a characteristic without the ev permission -> -70406
	my ( undef, $ro_iid ) = find_char( $json->decode($acc_body), '30' );
	$put = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $ro_iid, ev => \1 } ] } );
	( $status, undef, my $body ) =
	    dispatch( $hap, 'PUT', '/characteristics', $put, $session );
	is( $status, 207, 'unsupported subscription returns 207' );
	is( $json->decode($body)->{characteristics}[0]{status},
		-70406,
		'[HAP-HTTP §12] notification-not-supported is -70406' );
};

# The events below drive the engine without the timer contract: no
# after/cancel was injected, so the host calls flush_events itself.
# That covers the timer-less path of the engine.

subtest '[HAP-HTTP §14][HAP-HTTP §16.4] EVENT/1.0 notifications' => sub {
	my $hap = make_hap();
	my ( undef, undef, $acc_body ) =
	    dispatch( $hap, 'GET', '/accessories' );
	my ( $aid, $iid ) = find_char( $json->decode($acc_body), '25' );

	# Three sessions: a subscriber, the writer, and a bystander.
	# The writer is also subscribed. The bystander never
	# subscribes. They subscribe and write in the clear; the
	# sessions then turn encrypted before the flush, because
	# delivery needs an encrypted session and the event must
	# arrive in session frames.
	my $sub_sess    = verified_session( $hap, 'subscriber' );
	my $writer_sess = verified_session( $hap, 'writer' );
	my $other_sess  = verified_session( $hap, 'bystander' );

	my $subscribe = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $iid, ev => \1 } ] } );
	for my $sess ( $sub_sess, $writer_sess ) {
		my ( $status, undef, undef ) = dispatch( $hap, 'PUT',
			'/characteristics', $subscribe, $sess );
		is( $status, 204, 'subscription accepted' );
	}

	# A write through the PUT handler queues an event. The On type
	# is not exempt from coalescing. Thus delivery occurs on the
	# post-window flush.
	my $put = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $iid, value => \1 } ] } );
	my ( $status, undef, undef ) =
	    dispatch( $hap, 'PUT', '/characteristics', $put, $writer_sess );
	is( $status, 204, 'value write accepted' );

	$_->set_encryption( $ACC_TO_CTRL, $CTRL_TO_ACC )
	    for ( $sub_sess, $writer_sess, $other_sess );
	$OUT{ $_->id } = '' for ( $sub_sess, $writer_sess, $other_sess );
	$hap->flush_events;

	ok( length( $OUT{ $sub_sess->id } ) > 0,
		'write via PUT handler delivers an event to the subscriber' );
	is( $OUT{ $other_sess->id }, '',
		'subscriptions are per-connection: bystander receives nothing'
	);
	is( $OUT{ $writer_sess->id }, '',
		'originating connection receives no event for its own write' );

	# Decrypt the frame. Check the EVENT/1.0 message format.
	my $plain = client_decrypt( $sub_sess, $OUT{ $sub_sess->id } );
	like( $plain, qr{^EVENT/1\.0 200 OK\r\n},
		'event starts with EVENT/1.0 200 OK' );
	like( $plain, qr{Content-Type: application/hap\+json\r\n},
		'event content type is application/hap+json' );
	my ($event_body) = $plain =~ /\r\n\r\n(.*)$/s;
	my $data = $json->decode($event_body);
	is( $data->{characteristics}[0]{aid}, $aid, 'event has aid' );
	is( $data->{characteristics}[0]{iid}, $iid, 'event has iid' );
	ok( $data->{characteristics}[0]{value},
		'event carries the new value (true)' );

	# An unsubscribe with ev:false stops delivery. The sessions
	# are encrypted now, so these requests travel in session
	# frames and prove that receive decrypts them.
	my $unsubscribe = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $iid, ev => \0 } ] } );
	dispatch( $hap, 'PUT', '/characteristics', $unsubscribe, $sub_sess );
	$put = $json->encode( { characteristics =>
		    [ { aid => $aid, iid => $iid, value => \0 } ] } );
	dispatch( $hap, 'PUT', '/characteristics', $put, $writer_sess );
	$OUT{ $sub_sess->id } = '';
	$hap->flush_events;
	is( $OUT{ $sub_sess->id }, '',
		'unsubscribed session receives nothing' );

	# A session that disconnects loses all its subscriptions
	dispatch( $hap, 'PUT', '/characteristics', $subscribe, $sub_sess );
	ok( exists $hap->{event_subscriptions}{"$aid.$iid"}{ $sub_sess->id },
		'session re-subscribed' );
	$hap->session_close($sub_sess);
	ok( !exists $hap->{event_subscriptions}{"$aid.$iid"}{ $sub_sess->id },
		'subscriptions purged on disconnect' );

	# The event coalescing delay is 250ms
	is( Protocol::HAP::Server::EVENT_COALESCE_DELAY(),
		0.250, 'coalescing delay is 250ms' );
};

subtest '[HAP-HTTP §14] device-side change delivers event with device aid'
    => sub {
	my $hap = Protocol::HAP::Server->new(
		pin    => '123-45-678',
		name   => 'Conformance Bridge',
		store  => Protocol::HAP::Store::Memory->new,
		output => sub ( $session, $bytes ) {
			$OUT{ $session->id } .= $bytes;
		},
	);
	my $mqtt   = App::OpenHAP::TestMock::MQTT->new;
	my $heater = App::OpenHAP::Tasmota::Heater->new(
		aid         => 2,
		name        => 'Test Heater',
		mqtt_topic  => 'heater',
		mqtt_client => $mqtt,
	);
	$hap->add_accessory($heater);
	$heater->subscribe_mqtt;

	my $sub_sess = verified_session( $hap, 'subscriber' );
	my $subscribe = $json->encode( { characteristics =>
		    [ { aid => 2, iid => 11, ev => \1 } ] } );
	dispatch( $hap, 'PUT', '/characteristics', $subscribe, $sub_sess );
	$sub_sess->set_encryption( $ACC_TO_CTRL, $CTRL_TO_ACC );
	$OUT{ $sub_sess->id } = '';

	# A Tasmota state report reaches the subscriber as an event.
	# The event carries the device aid, not the bridge aid.
	$mqtt->simulate_message( 'stat/heater/POWER', 'ON' );
	$hap->flush_events;

	ok( length( $OUT{ $sub_sess->id } ) > 0,
		'MQTT state change delivers an event' );
	my $plain = client_decrypt( $sub_sess, $OUT{ $sub_sess->id } );
	my ($event_body) = ( $plain // '' ) =~ /\r\n\r\n(.*)$/s;
	my $data = $json->decode( $event_body // '{}' );
	is( $data->{characteristics}[0]{aid}, 2,
		'event carries the device aid' );
	is( $data->{characteristics}[0]{iid}, 11,
		'event carries the changed iid' );
	ok( $data->{characteristics}[0]{value}, 'event value is true' );
};

done_testing();
