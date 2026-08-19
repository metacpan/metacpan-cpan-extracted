#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/HAP-Pairing.md
#
# The tests script the controller side of pair-setup and pair-verify
# inline from the spec formulas. They use Math::BigInt for SRP and
# Protocol::HAP::Crypto primitives for the rest. The controller side is
# independent of the accessory-side modules under test.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;
use File::Temp qw(tempdir);

BEGIN {
	eval {
		require Math::BigInt;
		require Digest::SHA;
		require Crypt::Ed25519;
		require Crypt::Curve25519;
		require Crypt::AuthEnc::ChaCha20Poly1305;
	};
	if ($@) {
		plan skip_all => 'Crypto dependencies not available';
	}
}

use Digest::SHA qw(sha512);

use_ok('Protocol::HAP::Crypto');
use_ok('Protocol::HAP::SRP');
use_ok('Protocol::HAP::Pairing');
use_ok('Protocol::HAP::Session');
use_ok('Protocol::HAP::Store::File');
use_ok('Protocol::HAP::TLV');

my $PIN = '123-45-678';

sub b2i ($bytes) { Math::BigInt->from_hex( unpack( 'H*', $bytes ) ) }

sub i2b ( $int, $len = undef )
{
	return Protocol::HAP::SRP::_bigint_to_bytes( $int, $len );
}

sub make_pairing ( $storage = undef )
{
	$storage //= Protocol::HAP::Store::File->new(
		path => tempdir( CLEANUP => 1 ) );
	my ( $ltsk, $ltpk ) = Protocol::HAP::Crypto->ed25519_keypair;
	my $pairing = Protocol::HAP::Pairing->new(
		pin            => $PIN,
		store         => $storage,
		accessory_ltsk => $ltsk,
		accessory_ltpk => $ltpk,
	);
	$pairing->reset_auth_attempts;
	return ( $pairing, $storage, $ltpk );
}

sub tlv_field ( $response, $type )
{
	my %tlv = Protocol::HAP::TLV::decode($response);
	return $tlv{$type};
}

sub error_code ($response)
{
	my $error =
	    tlv_field( $response, Protocol::HAP::Pairing::kTLVType_Error() );
	return defined $error ? unpack( 'C', $error ) : undef;
}

# Do client-side SRP as HAP-Pairing.md §2.5 specifies. The function
# does not use Protocol::HAP::SRP state. It returns (A_bytes, M1, K).
sub client_srp ( $salt, $B_bytes, $pin )
{
	my $I = 'Pair-Setup';
	( my $P = $pin ) =~ s/-//g;

	my $N = b2i($Protocol::HAP::SRP::N_3072);
	my $g = Math::BigInt->new(5);

	my $a = b2i( Protocol::HAP::Crypto->random_bytes(32) );
	my $A = $g->copy->bmodpow( $a, $N );

	my $u = b2i( sha512( i2b( $A, 384 ) . i2b( b2i($B_bytes), 384 ) ) );
	my $x = b2i( sha512( $salt . sha512("$I:$P") ) );
	my $k = b2i( sha512( i2b($N) . i2b( $g, 384 ) ) );

	# S = (B - k*g^x)^(a + u*x) mod N
	my $gx   = $g->copy->bmodpow( $x, $N );
	my $base = ( b2i($B_bytes) - ( $k * $gx ) ) % $N;
	my $S    = $base->bmodpow( $a + $u * $x, $N );
	my $K    = sha512( i2b($S) );

	# M1 = H(H(N) xor H(g) | H(I) | s | PAD(A) | PAD(B) | K)
	my $M1 = sha512( ( sha512( i2b($N) ) ^. sha512( i2b($g) ) )
		. sha512($I)
		    . $salt
		    . i2b( $A, 384 )
		    . i2b( b2i($B_bytes), 384 )
		    . $K );

	return ( i2b( $A, 384 ), $M1, $K );
}

# Drive pair-setup M1..M4 against a pairing handler with a given PIN.
# It returns (m4_response, K, session).
sub run_m1_to_m4 ( $pairing, $pin )
{
	my $session = Protocol::HAP::Session->new( id => 9001 );

	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	my $m2 = $pairing->handle_pair_setup( $m1, $session );

	my $salt = tlv_field( $m2, Protocol::HAP::Pairing::kTLVType_Salt() );
	my $B = tlv_field( $m2, Protocol::HAP::Pairing::kTLVType_PublicKey() );
	return unless defined $salt && defined $B;

	my ( $A, $M1, $K ) = client_srp( $salt, $B, $pin );

	my $m3 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),     pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_PublicKey(), $A,
		Protocol::HAP::Pairing::kTLVType_Proof(),     $M1,
	);
	my $m4 = $pairing->handle_pair_setup( $m3, $session );

	return ( $m4, $K, $session, $A, $M1 );
}

subtest '[HAP-Pairing §1] HKDF-SHA-512 known-answer vector' => sub {

	# RFC 5869 test case 1 parameters with SHA-512
	my $okm = Protocol::HAP::Crypto->hkdf_sha512(
		"\x0b" x 22,
		pack( 'H*', '000102030405060708090a0b0c' ),
		pack( 'H*', 'f0f1f2f3f4f5f6f7f8f9' ), 42
	);
	is( unpack( 'H*', $okm ),
		'832390086cda71fb47625bb5ceb168e4'
		    . 'c8e26a1a16ed34d9fc7fe92c14815793'
		    . '38da362cb8d9f925d7cb',
		'HKDF-SHA-512 output matches published vector'
	);
};

subtest '[HAP-Pairing §1] Ed25519 RFC 8032 known-answer vector' => sub {
	my $public = pack( 'H*',
		'd75a980182b10ab7d54bfed3c964073a'
		    . '0ee172f3daa62325af021a68f707511a' );
	my $signature = pack( 'H*',
		'e5564300c360ac729086e2cc806e828a'
		    . '84877f1eb8e5d974d873e06522490155'
		    . '5fb8821590a33bacc61e39701cf9b46b'
		    . 'd25bf5f0595bbe24655141438e7a100b' );

	ok( Protocol::HAP::Crypto->ed25519_verify( $signature, '', $public ),
		'RFC 8032 TEST 1 signature verifies' );
	ok( !Protocol::HAP::Crypto->ed25519_verify( $signature, 'x', $public ),
		'RFC 8032 signature fails for different message' );

	# Sign/verify round-trip with a generated keypair
	my ( $ltsk, $ltpk ) = Protocol::HAP::Crypto->ed25519_keypair;
	my $sig = Protocol::HAP::Crypto->ed25519_sign( 'message', $ltsk, $ltpk );
	ok( Protocol::HAP::Crypto->ed25519_verify( $sig, 'message', $ltpk ),
		'generated keypair round-trips' );
};

subtest '[HAP-Pairing §1] X25519 RFC 7748 known-answer vector' => sub {
	my $a = Crypt::Curve25519::curve25519_secret_key(
		pack( 'H*',
			'77076d0a7318a57d3c16c17251b26645'
			    . 'df4c2f87ebc0992ab177fba51db92c2a' ) );
	my $b = Crypt::Curve25519::curve25519_secret_key(
		pack( 'H*',
			'5dab087e624a8a4b79e17f8b83800ee6'
			    . '6f3bb1292618b6fd1c2f8b27ff88e0eb' ) );

	my $a_pub = Crypt::Curve25519::curve25519_public_key($a);
	my $b_pub = Crypt::Curve25519::curve25519_public_key($b);

	is( unpack( 'H*', $a_pub ),
		'8520f0098930a754748b7ddcb43ef75a'
		    . '0dbf3a0d26381af4eba4a98eaa9b4e6a',
		'RFC 7748 public key for a' );
	is( unpack( 'H*', $b_pub ),
		'de9edb7d7b7dc1b4d35b61c2ece43537'
		    . '3f8343c85b78674dadfc7e146f882b4f',
		'RFC 7748 public key for b' );
	is(
		unpack( 'H*',
			Protocol::HAP::Crypto->x25519_shared_secret( $a, $b_pub ) ),
		'4a5d9d5ba4ce2de1728e3bf480350f25'
		    . 'e07e21c947d19e3376f09b3c1e161742',
		'RFC 7748 shared secret'
	);
	is(
		unpack( 'H*',
			Protocol::HAP::Crypto->x25519_shared_secret( $b, $a_pub ) ),
		'4a5d9d5ba4ce2de1728e3bf480350f25'
		    . 'e07e21c947d19e3376f09b3c1e161742',
		'shared secret agrees from both sides'
	);
};

subtest '[HAP-Pairing §2.2] SRP-6a group parameters' => sub {

	# RFC 5054 3072-bit prime, transcribed from the spec text
	my $rfc5054_3072 =
	      'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1'
	    . '29024E088A67CC74020BBEA63B139B22514A08798E3404DD'
	    . 'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245'
	    . 'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
	    . 'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D'
	    . 'C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F'
	    . '83655D23DCA3AD961C62F356208552BB9ED529077096966D'
	    . '670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B'
	    . 'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9'
	    . 'DE2BCBF6955817183995497CEA956AE515D2261898FA0510'
	    . '15728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64'
	    . 'ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7'
	    . 'ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6B'
	    . 'F12FFA06D98A0864D87602733EC86A64521F2B18177B200C'
	    . 'BBE117577A615D6C770988C0BAD946E208E24FA074E5AB31'
	    . '43DB5BFCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF';

	is( uc( unpack( 'H*', $Protocol::HAP::SRP::N_3072 ) ),
		$rfc5054_3072, 'N is the RFC 5054 3072-bit prime' );
	is( length($Protocol::HAP::SRP::N_3072), 384, 'N is 384 bytes' );
	is( $Protocol::HAP::SRP::g, 5, 'g is 5' );

	my $srp = Protocol::HAP::SRP->new( password => $PIN );
	is( $srp->{username}, 'Pair-Setup', 'I is "Pair-Setup"' );
	is( $srp->{password}, '12345678',
		'P is the 8-digit setup code without dashes' );

	# x = H(s | H(I ":" P)) and v = g^x mod N with a fixed salt
	my $salt = pack( 'H*', '00' x 15 . '01' );
	my $v    = $srp->compute_verifier($salt);
	my $x    = b2i( sha512( $salt . sha512('Pair-Setup:12345678') ) );
	my $expected_v =
	    Math::BigInt->new(5)
	    ->bmodpow( $x, b2i($Protocol::HAP::SRP::N_3072) );
	ok( $v == $expected_v, 'verifier v = g^x mod N' );
};

subtest '[HAP-Pairing §2][HAP-Pairing §2.1] pair setup state machine' =>
    sub {
	my ($pairing) = make_pairing();
	my $session = Protocol::HAP::Session->new( id => 9002 );

	# The handler rejects an invalid state value
	my $bogus = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 99 ),
	);
	is( error_code( $pairing->handle_pair_setup( $bogus, $session ) ),
		Protocol::HAP::Pairing::kTLVError_Unknown(),
		'invalid state rejected with kTLVError_Unknown' );

	# The handler rejects M3 without a preceding M1
	my $m3 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),     pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_PublicKey(), 'A' x 384,
		Protocol::HAP::Pairing::kTLVType_Proof(),     'P' x 64,
	);
	is( error_code( $pairing->handle_pair_setup( $m3, $session ) ),
		Protocol::HAP::Pairing::kTLVError_Unknown(),
		'M3 before M1 rejected' );

};

subtest '[HAP-Pairing §3.1] pair verify state machine' => sub {
	my ($pairing) = make_pairing();
	my $session = Protocol::HAP::Session->new( id => 9003 );

	# The handler rejects an invalid state value
	my $bogus = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 99 ),
	);
	is( error_code( $pairing->handle_pair_verify( $bogus, $session ) ),
		Protocol::HAP::Pairing::kTLVError_Unknown(),
		'invalid state rejected with kTLVError_Unknown' );

	# The handler rejects M3 without a preceding M1
	my $m3 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_EncryptedData(), 'X' x 32,
	);
	is( error_code( $pairing->handle_pair_verify( $m3, $session ) ),
		Protocol::HAP::Pairing::kTLVError_Unknown(),
		'verify M3 before M1 rejected' );
};

subtest '[HAP-Pairing §2.3][HAP-Pairing §2.4] M1 -> M2 shape' => sub {
	my ($pairing) = make_pairing();
	my $session = Protocol::HAP::Session->new( id => 9004 );

	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	my $m2 = $pairing->handle_pair_setup( $m1, $session );

	is( unpack( 'C',
		    tlv_field( $m2, Protocol::HAP::Pairing::kTLVType_State() ) ),
		2, 'M2 has State 0x02' );
	is( length( tlv_field( $m2, Protocol::HAP::Pairing::kTLVType_Salt() ) ),
		16, 'M2 salt is 16 random bytes' );
	is(
		length( tlv_field(
			$m2, Protocol::HAP::Pairing::kTLVType_PublicKey() ) ),
		384,
		'M2 public key B is 384 bytes'
	);
	ok( !defined error_code($m2), 'M2 success carries no Error TLV' );

};

subtest '[HAP-Pairing §2.4] M2 error responses' => sub {

	# Already paired -> 0x06 Unavailable
	my ( $pairing, $storage ) = make_pairing();
	$storage->save_pairing( 'controller', 'X' x 32, 1 );
	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	my $session = Protocol::HAP::Session->new( id => 9005 );
	is( error_code( $pairing->handle_pair_setup( $m1, $session ) ),
		Protocol::HAP::Pairing::kTLVError_Unavailable(),
		'already paired returns 0x06 Unavailable' );

	# Another pairing in progress -> 0x07 Busy
	my ($pairing2) = make_pairing();
	my $s1 = Protocol::HAP::Session->new( id => 9006 );
	my $s2 = Protocol::HAP::Session->new( id => 9007 );
	$pairing2->handle_pair_setup( $m1, $s1 );
	is( error_code( $pairing2->handle_pair_setup( $m1, $s2 ) ),
		Protocol::HAP::Pairing::kTLVError_Busy(),
		'concurrent pairing returns 0x07 Busy' );
};

subtest '[HAP-Pairing §2.5][HAP-Pairing §2.6] M3 -> M4 SRP proof' => sub {

	# Correct PIN: M4 returns a verifiable server proof M2
	my ($pairing) = make_pairing();
	my ( $m4, $K, $session, $A, $M1 ) = run_m1_to_m4( $pairing, $PIN );

	is( unpack( 'C',
		    tlv_field( $m4, Protocol::HAP::Pairing::kTLVType_State() ) ),
		4, 'M4 has State 0x04' );
	ok( !defined error_code($m4), 'correct proof accepted' );

	my $proof = tlv_field( $m4, Protocol::HAP::Pairing::kTLVType_Proof() );
	is( length($proof), 64, 'M4 proof is 64 bytes (SHA-512)' );

	# M2 = H(PAD(A) | M1 | K). The test checks it on the client
	# side.
	is( unpack( 'H*', $proof ),
		unpack( 'H*', sha512( $A . $M1 . $K ) ),
		'server proof M2 = H(A | M1 | K) verifies' );

	# Wrong PIN: M4 returns 0x02 Authentication
	my ($pairing2) = make_pairing();
	my ($m4_bad) = run_m1_to_m4( $pairing2, '876-54-321' );
	is( error_code($m4_bad),
		Protocol::HAP::Pairing::kTLVError_Authentication(),
		'wrong setup code returns 0x02 Authentication in M4' );
	is( $pairing2->get_failed_attempts,
		1, 'failed proof increments attempt counter' );

	# A mod N == 0: the handler rejects it before proof verification
	my ($pairing3) = make_pairing();
	my $s = Protocol::HAP::Session->new( id => 9008 );
	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	$pairing3->handle_pair_setup( $m1, $s );
	my $m3 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),     pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_PublicKey(), "\x00" x 384,
		Protocol::HAP::Pairing::kTLVType_Proof(),     'X' x 64,
	);
	is( error_code( $pairing3->handle_pair_setup( $m3, $s ) ),
		Protocol::HAP::Pairing::kTLVError_Authentication(),
		'A mod N == 0 rejected with 0x02' );
};

subtest '[HAP-Pairing §2.7][HAP-Pairing §2.8] M5 -> M6 exchange' => sub {
	my ( $pairing, $storage, $accessory_ltpk ) = make_pairing();
	my ( $m4, $K, $session ) = run_m1_to_m4( $pairing, $PIN );
	ok( !defined error_code($m4), 'SRP phase succeeded' );

	# [HAP-Pairing §4/Pair Setup Encryption] session encryption key
	my $encrypt_key = Protocol::HAP::Crypto->hkdf_sha512( $K,
		'Pair-Setup-Encrypt-Salt', 'Pair-Setup-Encrypt-Info', 32 );

	# Controller long-term identity and signature
	# [HAP-Pairing §4/Controller Signature]
	my ( $ios_ltsk, $ios_ltpk ) =
	    Protocol::HAP::Crypto->ed25519_keypair;
	my $ios_id = 'ios-controller-1';
	my $ios_x  = Protocol::HAP::Crypto->hkdf_sha512(
		$K,
		'Pair-Setup-Controller-Sign-Salt',
		'Pair-Setup-Controller-Sign-Info', 32
	);
	my $ios_signature =
	    Protocol::HAP::Crypto->ed25519_sign( $ios_x . $ios_id . $ios_ltpk,
		$ios_ltsk, $ios_ltpk );

	my $inner = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_Identifier(), $ios_id,
		Protocol::HAP::Pairing::kTLVType_PublicKey(),  $ios_ltpk,
		Protocol::HAP::Pairing::kTLVType_Signature(),  $ios_signature,
	);

	# [HAP-Pairing §5/M5] nonce PS-Msg05
	is( unpack( 'H*', pack('x[4]') . 'PS-Msg05' ),
		'0000000050532d4d73673035', 'M5 nonce is PS-Msg05' );
	my ( $encrypted, $tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $encrypt_key,
		pack('x[4]') . 'PS-Msg05', $inner );

	my $m5 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 5 ),
		Protocol::HAP::Pairing::kTLVType_EncryptedData(),
		$encrypted . $tag,
	);
	my $m6 = $pairing->handle_pair_setup( $m5, $session );

	is( unpack( 'C',
		    tlv_field( $m6, Protocol::HAP::Pairing::kTLVType_State() ) ),
		6, 'M6 has State 0x06' );
	ok( !defined error_code($m6), 'M5 accepted' );

	# The accessory stores the pairing with admin permissions
	my $pairings = $storage->load_pairings();
	ok( exists $pairings->{$ios_id},
		'[HAP-Pairing §6] controller pairing persisted' );
	is( $pairings->{$ios_id}{ltpk},
		$ios_ltpk,
		'[HAP-Pairing §6.2] pairing ID, LTPK and permissions stored'
	);
	is( $pairings->{$ios_id}{permissions},
		1,
		'[HAP-Pairing §6.1] initial pairing has admin permissions' );

	# Decrypt M6 with nonce PS-Msg06 ([HAP-Pairing §5/M6])
	my $m6_data =
	    tlv_field( $m6, Protocol::HAP::Pairing::kTLVType_EncryptedData() );
	my $m6_tag = substr( $m6_data, -16, 16, '' );
	my $m6_plain =
	    Protocol::HAP::Crypto->chacha20poly1305_decrypt( $encrypt_key,
		pack('x[4]') . 'PS-Msg06', $m6_data, $m6_tag );
	ok( defined $m6_plain, 'M6 sub-TLV decrypts with PS-Msg06 nonce' );

	# Verify the accessory signature
	# ([HAP-Pairing §4/Accessory Signature])
	my %m6_inner = Protocol::HAP::TLV::decode($m6_plain);
	my $acc_id =
	    $m6_inner{ Protocol::HAP::Pairing::kTLVType_Identifier() };
	my $acc_ltpk =
	    $m6_inner{ Protocol::HAP::Pairing::kTLVType_PublicKey() };
	my $acc_sig =
	    $m6_inner{ Protocol::HAP::Pairing::kTLVType_Signature() };

	is( $acc_ltpk, $accessory_ltpk, 'M6 carries accessory LTPK' );
	like( $acc_id, qr/^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/,
		'accessory pairing ID is MAC-like' );

	my $acc_x = Protocol::HAP::Crypto->hkdf_sha512(
		$K,
		'Pair-Setup-Accessory-Sign-Salt',
		'Pair-Setup-Accessory-Sign-Info', 32
	);
	ok(
		Protocol::HAP::Crypto->ed25519_verify(
			$acc_sig, $acc_x . $acc_id . $acc_ltpk, $acc_ltpk
		),
		'accessory signature verifies'
	);

};

subtest '[HAP-Pairing §3] pair-verify handshake' => sub {

	# Pair first so the accessory knows the controller LTPK
	my ( $pairing, $storage, $accessory_ltpk ) = make_pairing();
	my ( $ios_ltsk, $ios_ltpk ) =
	    Protocol::HAP::Crypto->ed25519_keypair;
	my $ios_id = 'ios-controller-1';
	$storage->save_pairing( $ios_id, $ios_ltpk, 1 );

	my $session = Protocol::HAP::Session->new( id => 9009 );

	# [HAP-Pairing §3.2] M1: controller ephemeral public key
	my ( $ios_secret, $ios_public ) =
	    Protocol::HAP::Crypto->x25519_keypair;
	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),     pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_PublicKey(), $ios_public,
	);
	my $m2 = $pairing->handle_pair_verify( $m1, $session );

	# [HAP-Pairing §3.3] M2: accessory public key + encrypted proof
	is( unpack( 'C',
		    tlv_field( $m2, Protocol::HAP::Pairing::kTLVType_State() ) ),
		2, 'M2 has State 0x02' );
	my $acc_public =
	    tlv_field( $m2, Protocol::HAP::Pairing::kTLVType_PublicKey() );
	is( length($acc_public), 32,
		'M2 carries 32-byte Curve25519 public key' );

	my $shared =
	    Protocol::HAP::Crypto->x25519_shared_secret( $ios_secret,
		$acc_public );

	# [HAP-Pairing §4/Pair Verify Encryption] + [HAP-Pairing §5/PV M2]
	my $pv_key = Protocol::HAP::Crypto->hkdf_sha512( $shared,
		'Pair-Verify-Encrypt-Salt', 'Pair-Verify-Encrypt-Info', 32 );
	my $m2_data =
	    tlv_field( $m2, Protocol::HAP::Pairing::kTLVType_EncryptedData() );
	my $m2_tag = substr( $m2_data, -16, 16, '' );
	my $m2_plain =
	    Protocol::HAP::Crypto->chacha20poly1305_decrypt( $pv_key,
		pack('x[4]') . 'PV-Msg02', $m2_data, $m2_tag );
	ok( defined $m2_plain, 'M2 sub-TLV decrypts with PV-Msg02 nonce' );

	my %m2_inner = Protocol::HAP::TLV::decode($m2_plain);
	my $acc_id = $m2_inner{ Protocol::HAP::Pairing::kTLVType_Identifier() };
	my $acc_sig = $m2_inner{ Protocol::HAP::Pairing::kTLVType_Signature() };
	ok(
		Protocol::HAP::Crypto->ed25519_verify(
			$acc_sig, $acc_public . $acc_id . $ios_public,
			$accessory_ltpk
		),
		'accessory signature over AccessoryInfo verifies'
	);

	# [HAP-Pairing §3.4] M3: controller proof
	my $ios_sig = Protocol::HAP::Crypto->ed25519_sign(
		$ios_public . $ios_id . $acc_public,
		$ios_ltsk, $ios_ltpk );
	my $m3_inner = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_Identifier(), $ios_id,
		Protocol::HAP::Pairing::kTLVType_Signature(),  $ios_sig,
	);
	my ( $m3_encrypted, $m3_tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $pv_key,
		pack('x[4]') . 'PV-Msg03', $m3_inner );
	my $m3 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_EncryptedData(),
		$m3_encrypted . $m3_tag,
	);
	my $m4 = $pairing->handle_pair_verify( $m3, $session );

	# [HAP-Pairing §3.5] M4: success. The session becomes encrypted.
	is( unpack( 'C',
		    tlv_field( $m4, Protocol::HAP::Pairing::kTLVType_State() ) ),
		4, 'M4 has State 0x04' );
	ok( !defined error_code($m4), 'pair-verify succeeded' );
	ok( $session->is_verified,  'session marked verified' );
	ok( $session->is_encrypted, 'session encryption enabled' );

	# [HAP-Pairing §4/Session Read Key][HAP-Pairing §4/Session Write Key]
	# The accessory encrypts with the Read key and decrypts with the
	# Write key
	my $read_key =
	    Protocol::HAP::Crypto->hkdf_sha512( $shared, 'Control-Salt',
		'Control-Read-Encryption-Key', 32 );
	my $frame = $session->encrypt('event data');
	my $aad   = substr( $frame, 0, 2 );
	my $plain = Protocol::HAP::Crypto->chacha20poly1305_decrypt(
		$read_key,
		pack( 'x[4]Q<', 0 ),
		substr( $frame, 2, -16 ),
		substr( $frame, -16 ), $aad
	);
	is( $plain, 'event data',
		'accessory-to-controller key is Control-Read-Encryption-Key'
	);

	# The accessory rejects an unknown controller with 0x02
	my $session2 = Protocol::HAP::Session->new( id => 9010 );
	my ( $pairing2, $storage2 ) = make_pairing();
	my $m2_2 = $pairing2->handle_pair_verify( $m1, $session2 );
	my $acc_public2 =
	    tlv_field( $m2_2, Protocol::HAP::Pairing::kTLVType_PublicKey() );
	my $shared2 =
	    Protocol::HAP::Crypto->x25519_shared_secret( $ios_secret,
		$acc_public2 );
	my $pv_key2 = Protocol::HAP::Crypto->hkdf_sha512( $shared2,
		'Pair-Verify-Encrypt-Salt', 'Pair-Verify-Encrypt-Info', 32 );
	my $ios_sig2 = Protocol::HAP::Crypto->ed25519_sign(
		$ios_public . $ios_id . $acc_public2,
		$ios_ltsk, $ios_ltpk );
	my $m3_inner2 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_Identifier(), $ios_id,
		Protocol::HAP::Pairing::kTLVType_Signature(),  $ios_sig2,
	);
	my ( $enc2, $tag2 ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $pv_key2,
		pack('x[4]') . 'PV-Msg03', $m3_inner2 );
	my $m3_2 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 3 ),
		Protocol::HAP::Pairing::kTLVType_EncryptedData(), $enc2 . $tag2,
	);
	is( error_code( $pairing2->handle_pair_verify( $m3_2, $session2 ) ),
		Protocol::HAP::Pairing::kTLVError_Authentication(),
		'[HAP-Pairing §3.5] unknown controller rejected with 0x02' );
};

subtest '[HAP-Pairing §8] authentication attempt limits' => sub {
	my $storage = Protocol::HAP::Store::File->new(
		path => tempdir( CLEANUP => 1 ) );
	my ( $pairing, undef, undef ) = make_pairing($storage);

	# The limit is 100 attempts. At the limit, M1 returns 0x05
	# MaxTries.
	is( Protocol::HAP::Pairing::MAX_AUTH_ATTEMPTS(),
		100, 'maximum unsuccessful attempts is 100' );

	$pairing->{failed_auth_attempts} = 100;
	my $session = Protocol::HAP::Session->new( id => 9011 );
	my $m1      = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	is( error_code( $pairing->handle_pair_setup( $m1, $session ) ),
		Protocol::HAP::Pairing::kTLVError_MaxTries(),
		'M1 at the limit returns 0x05 MaxTries' );

	# The accessory stores the counter persistently. Thus the
	# counter survives a restart.
	my ($pairing2) = run_failed_attempt($storage);
	is( $storage->get_auth_attempts, 1, 'failed attempt persisted' );

	my $revived = Protocol::HAP::Pairing->new(
		pin            => $PIN,
		store         => $storage,
		accessory_ltsk => 'x' x 64,
		accessory_ltpk => 'y' x 32,
	);
	is( $revived->get_failed_attempts,
		1, 'attempt counter restored from storage on restart' );

	# The counter resets only after the SRP proof
	# verification succeeds
	my ( $pairing3, undef, undef ) = make_pairing($storage);
	my ($m4) = run_m1_to_m4( $pairing3, $PIN );
	ok( !defined error_code($m4), 'successful SRP proof' );
	is( $pairing3->get_failed_attempts,
		0, 'counter reset after successful SRP proof' );
	is( $storage->get_auth_attempts, 0, 'reset persisted' );

};

# Run one failed pairing attempt with a wrong PIN against $storage
sub run_failed_attempt ($storage)
{
	my ( $ltsk, $ltpk ) = Protocol::HAP::Crypto->ed25519_keypair;
	my $pairing = Protocol::HAP::Pairing->new(
		pin            => $PIN,
		store         => $storage,
		accessory_ltsk => $ltsk,
		accessory_ltpk => $ltpk,
	);
	$pairing->reset_auth_attempts;
	run_m1_to_m4( $pairing, '876-54-321' );
	return $pairing;
}

done_testing();
