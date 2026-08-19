#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/HAP-Encryption.md

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

BEGIN {
	eval { require Crypt::AuthEnc::ChaCha20Poly1305; };
	if ($@) {
		plan skip_all => 'CryptX not available';
	}
}

use_ok('Protocol::HAP::Crypto');
use_ok('Protocol::HAP::Session');

# Fixed 32-byte keys for deterministic frame tests
my $key_a2c = pack( 'H*', '11' x 32 );
my $key_c2a = pack( 'H*', '22' x 32 );

# The accessory-side session encrypts with a2c and decrypts with c2a
sub accessory_session ()
{
	my $session = Protocol::HAP::Session->new( id => 9001 );
	$session->set_encryption( $key_a2c, $key_c2a );
	return $session;
}

# Decrypt an accessory frame on the controller side. The function
# uses the crypto primitives directly.
sub controller_decrypt ( $frame, $counter )
{
	my $aad        = substr( $frame, 0, 2 );
	my $length     = unpack( 'v', $aad );
	my $ciphertext = substr( $frame, 2, $length );
	my $tag        = substr( $frame, 2 + $length, 16 );
	my $nonce      = pack( 'x[4]Q<', $counter );
	return Protocol::HAP::Crypto->chacha20poly1305_decrypt( $key_a2c, $nonce,
		$ciphertext, $tag, $aad );
}

subtest '[HAP-Encryption §2] frame layout on raw bytes' => sub {
	my $session   = accessory_session();
	my $plaintext = "HTTP/1.1 200 OK\r\n\r\n";
	my $frame     = $session->encrypt($plaintext);

	is( length($frame), 2 + length($plaintext) + 16,
		'frame is 2-byte length + ciphertext + 16-byte tag' );
	is( unpack( 'v', substr( $frame, 0, 2 ) ),
		length($plaintext),
		'length field is little-endian plaintext length' );
	is( unpack( 'H*', substr( $frame, 0, 2 ) ),
		'1300',
		'[HAP-Encryption §8] 19-byte payload length field is 13 00' );
	isnt( substr( $frame, 2, length($plaintext) ),
		$plaintext, 'payload bytes are encrypted' );
};

subtest '[HAP-Encryption §2] max 1024 bytes plaintext per frame' => sub {
	my $session   = accessory_session();
	my $plaintext = 'A' x 2500;
	my $stream    = $session->encrypt($plaintext);

	# 2500 bytes -> frames of 1024, 1024, 452
	my @lengths;
	my $pos = 0;
	while ( $pos < length($stream) ) {
		my $length = unpack( 'v', substr( $stream, $pos, 2 ) );
		push @lengths, $length;
		$pos += 2 + $length + 16;
	}
	is_deeply( \@lengths, [ 1024, 1024, 452 ],
		'[HAP-Encryption §8] 2500 bytes split into 1024 + 1024 + 452'
	);
	is( length($stream), 2500 + 3 * 18,
		'[HAP-Encryption §8] total overhead is 18 bytes per frame' );
};

subtest '[HAP-Encryption §3] AAD is the length field' => sub {
	my $session = accessory_session();
	my $frame   = $session->encrypt('hello');

	# A decrypt with the frame's own AAD succeeds
	is( controller_decrypt( $frame, 0 ),
		'hello', 'decrypts with length field as AAD' );

	# A decrypt with a different AAD fails
	my $length     = unpack( 'v', substr( $frame, 0, 2 ) );
	my $ciphertext = substr( $frame, 2, $length );
	my $tag        = substr( $frame, 2 + $length, 16 );
	my $nonce      = pack( 'x[4]Q<', 0 );
	my $plaintext =
	    Protocol::HAP::Crypto->chacha20poly1305_decrypt( $key_a2c, $nonce,
		$ciphertext, $tag, pack( 'v', $length + 1 ) );
	ok( !defined $plaintext, 'wrong AAD fails authentication' );
};

subtest '[HAP-Encryption §4] nonce is 4 zero bytes + LE counter' => sub {
	my $session = accessory_session();
	my $frame0  = $session->encrypt('first');
	my $frame1  = $session->encrypt('second');

	# The counter starts at 0. It increments once for each frame in
	# each direction.
	is( controller_decrypt( $frame0, 0 ),
		'first', 'first frame uses counter 0' );
	is( controller_decrypt( $frame1, 1 ),
		'second', 'second frame uses counter 1' );
	ok( !defined controller_decrypt( $frame1, 0 ),
		'frame does not decrypt under the wrong counter' );

	# The direction counters are independent. The
	# controller->accessory counter starts at 0. Accessory->controller
	# traffic does not change it.
	my $c2a_nonce = pack( 'x[4]Q<', 0 );
	my ( $ciphertext, $tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $key_c2a, $c2a_nonce,
		'PUT /characteristics', pack( 'v', 20 ) );
	my $inbound = pack( 'v', 20 ) . $ciphertext . $tag;
	is( $session->decrypt($inbound),
		'PUT /characteristics',
		'[HAP-Encryption §5][HAP-Encryption §6] inbound frame '
		    . 'decrypts under its own direction counter' );

	# Nonce layout: 12 bytes, first 4 zero, counter little-endian
	is( unpack( 'H*', pack( 'x[4]Q<', 1 ) ),
		'000000000100000000000000', 'counter 1 nonce layout' );
};

subtest '[HAP-Encryption §7] ChaCha20-Poly1305 RFC 8439 vector' => sub {
	my $key = pack( 'H*',
		'808182838485868788898a8b8c8d8e8f'
		    . '909192939495969798999a9b9c9d9e9f' );
	my $nonce     = pack( 'H*', '070000004041424344454647' );
	my $aad       = pack( 'H*', '50515253c0c1c2c3c4c5c6c7' );
	my $plaintext = "Ladies and Gentlemen of the class of '99: "
	    . 'If I could offer you only one tip for the future, '
	    . 'sunscreen would be it.';

	my ( $ciphertext, $tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $key, $nonce,
		$plaintext, $aad );

	is( unpack( 'H*', $ciphertext ),
		'd31a8d34648e60db7b86afbc53ef7ec2'
		    . 'a4aded51296e08fea9e2b5a736ee62d6'
		    . '3dbea45e8ca9671282fafb69da92728b'
		    . '1a71de0a9e060b2905d6a5b67ecd3b36'
		    . '92ddbd7f2d778b8c9803aee328091b58'
		    . 'fab324e4fad675945585808b4831d7bc'
		    . '3ff4def08e4b7a9de576d26586cec64b'
		    . '6116',
		'RFC 8439 §2.8.2 ciphertext'
	);
	is( unpack( 'H*', $tag ),
		'1ae10b594f09e26a7e902ecbd0600691',
		'RFC 8439 §2.8.2 auth tag' );

	is(
		Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$key, $nonce, $ciphertext, $tag, $aad
		),
		$plaintext,
		'RFC 8439 vector decrypts'
	);
};

subtest '[HAP-Encryption §9] error handling' => sub {
	my $session = accessory_session();

	# Build a valid inbound frame. Then tamper with it.
	my $nonce = pack( 'x[4]Q<', 0 );
	my ( $ciphertext, $tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $key_c2a, $nonce,
		'GET /accessories', pack( 'v', 16 ) );
	my $good = pack( 'v', 16 ) . $ciphertext . $tag;

	# Bad auth tag
	my $tampered = $good;
	substr( $tampered, -1, 1 ) =
	    substr( $tampered, -1, 1 ) ^. "\x01";
	ok( !defined accessory_session()->decrypt($tampered),
		'bad auth tag fails decryption' );

	# Truncated frame (incomplete at EOF)
	my $truncated = substr( $good, 0, length($good) - 4 );
	ok( !defined accessory_session()->decrypt($truncated),
		'incomplete frame is an error' );

	# Frame length > 1024
	my $oversize = pack( 'v', 1025 ) . ( 'X' x ( 1025 + 16 ) );
	ok( !defined accessory_session()->decrypt($oversize),
		'frame length over 1024 is an error' );

	# The valid frame still decrypts. This is the control check.
	is( accessory_session()->decrypt($good),
		'GET /accessories',
		'[HAP-Encryption §5] control frame decrypts' );
};

subtest '[HAP-Encryption §1] session key derivation' => sub {

	# The keys for both directions derive from the shared secret
	# with Control-Salt
	my $shared = pack( 'H*', 'ab' x 32 );
	my $read_key =
	    Protocol::HAP::Crypto->hkdf_sha512( $shared, 'Control-Salt',
		'Control-Read-Encryption-Key', 32 );
	my $write_key =
	    Protocol::HAP::Crypto->hkdf_sha512( $shared, 'Control-Salt',
		'Control-Write-Encryption-Key', 32 );

	is( length($read_key),  32, 'AccessoryToControllerKey is 32 bytes' );
	is( length($write_key), 32, 'ControllerToAccessoryKey is 32 bytes' );
	isnt( unpack( 'H*', $read_key ),
		unpack( 'H*', $write_key ),
		'read and write keys differ' );

	# The accessory session encrypts outbound data with the read key
	my $session = Protocol::HAP::Session->new( id => 9002 );
	$session->set_encryption( $read_key, $write_key );
	my $frame = $session->encrypt('response');
	my $aad   = substr( $frame, 0, 2 );
	is(
		Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$read_key, pack( 'x[4]Q<', 0 ),
			substr( $frame, 2, -16 ),
			substr( $frame, -16 ), $aad
		),
		'response',
		'accessory outgoing data uses Control-Read-Encryption-Key'
	);
};

subtest '[HAP-Encryption §10] connection lifecycle' => sub {
	my $session = Protocol::HAP::Session->new( id => 9003 );

	# Before pair-verify the session passes data through unencrypted
	ok( !$session->is_encrypted, 'session starts unencrypted' );
	is( $session->encrypt('plain'), 'plain',
		'pre-verify data is not framed' );
	is( $session->decrypt('plain'), 'plain',
		'pre-verify inbound data is passed through' );

	# After key setup, the session frames and encrypts every byte
	$session->set_encryption( $key_a2c, $key_c2a );
	ok( $session->is_encrypted, 'session encrypted after key setup' );
	isnt( $session->encrypt('plain'), 'plain',
		'post-verify data is encrypted' );
};

done_testing();
