#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Protocol::HAP::Crypto');

# have($module): report if an optional Crypt library is installed
sub have ($module)
{
	my $path = $module =~ s{::}{/}gr . '.pm';
	return eval { require $path; 1 } ? 1 : 0;
}

# The randomness is core Perl. It never skips.
subtest 'random_bytes' => sub {
	for my $length ( 1, 16, 32, 64, 4096 ) {
		my $bytes = Protocol::HAP::Crypto->random_bytes($length);
		is( length($bytes), $length, "$length bytes" );
	}

	isnt(
		Protocol::HAP::Crypto->random_bytes(32),
		Protocol::HAP::Crypto->random_bytes(32),
		'two draws differ'
	);

	ok( !eval { Protocol::HAP::Crypto->random_bytes(0); 1 },
		'a length of zero is a programming error' );
	ok( !eval { Protocol::HAP::Crypto->random_bytes(-1); 1 },
		'a negative length is a programming error' );
	ok( !eval { Protocol::HAP::Crypto->random_bytes(undef); 1 },
		'a missing length is a programming error' );
};

subtest 'Ed25519 signatures' => sub {
	plan skip_all => 'Crypt::Ed25519 not available'
	    unless have('Crypt::Ed25519');

	my ( $secret, $public ) = Protocol::HAP::Crypto->ed25519_keypair;
	is( length($secret), 64, 'the secret key is 64 bytes' );
	is( length($public), 32, 'the public key is 32 bytes' );

	my $message   = 'the message to sign';
	my $signature = Protocol::HAP::Crypto->ed25519_sign( $message, $secret,
		$public );
	is( length($signature), 64, 'the signature is 64 bytes' );

	ok( Protocol::HAP::Crypto->ed25519_verify( $signature, $message, $public ),
		'the signature verifies' );
	ok(
		!Protocol::HAP::Crypto->ed25519_verify(
			$signature, 'a different message', $public
		),
		'a changed message does not verify'
	);

	my ( undef, $other ) = Protocol::HAP::Crypto->ed25519_keypair;
	ok( !Protocol::HAP::Crypto->ed25519_verify( $signature, $message, $other ),
		'another key does not verify' );
};

subtest 'X25519 key agreement' => sub {
	plan skip_all => 'Crypt::Curve25519 not available'
	    unless have('Crypt::Curve25519');

	my ( $a_secret, $a_public ) = Protocol::HAP::Crypto->x25519_keypair;
	my ( $b_secret, $b_public ) = Protocol::HAP::Crypto->x25519_keypair;

	is( length($a_secret), 32, 'the secret key is 32 bytes' );
	is( length($a_public), 32, 'the public key is 32 bytes' );

	is(
		Protocol::HAP::Crypto->x25519_shared_secret( $a_secret, $b_public ),
		Protocol::HAP::Crypto->x25519_shared_secret( $b_secret, $a_public ),
		'both sides derive the same secret'
	);

	my ( $c_secret, undef ) = Protocol::HAP::Crypto->x25519_keypair;
	isnt(
		Protocol::HAP::Crypto->x25519_shared_secret( $a_secret, $b_public ),
		Protocol::HAP::Crypto->x25519_shared_secret( $c_secret, $b_public ),
		'a third party derives a different secret'
	);
};

subtest 'HKDF over SHA-512' => sub {
	plan skip_all => 'Crypt::KeyDerivation not available'
	    unless have('Crypt::KeyDerivation');

	my $key = Protocol::HAP::Crypto->hkdf_sha512( 'input keying material',
		'salt', 'info', 32 );
	is( length($key), 32, 'the derived key has the asked-for length' );

	is(
		Protocol::HAP::Crypto->hkdf_sha512( 'ikm', 'salt', 'info', 32 ),
		Protocol::HAP::Crypto->hkdf_sha512( 'ikm', 'salt', 'info', 32 ),
		'the derivation is deterministic'
	);
	isnt(
		Protocol::HAP::Crypto->hkdf_sha512( 'ikm', 'salt', 'info',  32 ),
		Protocol::HAP::Crypto->hkdf_sha512( 'ikm', 'salt', 'other', 32 ),
		'a different info gives a different key'
	);
	is( length( Protocol::HAP::Crypto->hkdf_sha512( 'ikm', '', '', 64 ) ),
		64, 'a longer key is possible' );
};

subtest 'ChaCha20-Poly1305' => sub {
	plan skip_all => 'Crypt::AuthEnc::ChaCha20Poly1305 not available'
	    unless have('Crypt::AuthEnc::ChaCha20Poly1305');

	my $key   = Protocol::HAP::Crypto->random_bytes(32);
	my $nonce = Protocol::HAP::Crypto->random_bytes(12);
	my $text  = 'the plaintext';

	my ( $cipher, $tag ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $key, $nonce, $text );
	is( length($tag), 16, 'the tag is 16 bytes' );
	isnt( $cipher, $text, 'the ciphertext is not the plaintext' );

	is(
		Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$key, $nonce, $cipher, $tag
		),
		$text,
		'the plaintext comes back'
	);

	# A changed tag must not verify
	my $bad = $tag;
	substr( $bad, 0, 1 ) = chr( ord( substr( $bad, 0, 1 ) ) ^ 0xff );
	ok(
		!defined Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$key, $nonce, $cipher, $bad
		),
		'a forged tag does not verify'
	);

	# Additional data is authenticated, not encrypted
	my ( $c2, $t2 ) =
	    Protocol::HAP::Crypto->chacha20poly1305_encrypt( $key, $nonce, $text,
		'header' );
	is(
		Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$key, $nonce, $c2, $t2, 'header'
		),
		$text,
		'the same additional data verifies'
	);
	ok(
		!defined Protocol::HAP::Crypto->chacha20poly1305_decrypt(
			$key, $nonce, $c2, $t2, 'other'
		),
		'changed additional data does not verify'
	);
};

subtest 'the libraries load lazily and preload loads them all' => sub {
	plan skip_all => 'not every Crypt library is available'
	    unless have('Crypt::Ed25519')
	    && have('Crypt::Curve25519')
	    && have('Crypt::KeyDerivation')
	    && have('Crypt::AuthEnc::ChaCha20Poly1305');

	# A daemon that pledges without prot_exec cannot dlopen a shared
	# object later, so it warms every library up first.
	ok( defined Protocol::HAP::Crypto->preload, 'preload reports a count' );
	ok( Protocol::HAP::Crypto->preload == 0,
		'a second preload has nothing left to load' );

	for my $module (
		qw(Crypt::Ed25519 Crypt::Curve25519 Crypt::KeyDerivation
		Crypt::AuthEnc::ChaCha20Poly1305)
	    )
	{
		my $path = $module =~ s{::}{/}gr . '.pm';
		ok( $INC{$path}, "$module is loaded" );
	}
};

done_testing();
