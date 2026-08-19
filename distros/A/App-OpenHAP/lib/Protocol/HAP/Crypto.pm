# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Protocol::HAP::Crypto;
our $VERSION = '0.1.0';

# Protocol::HAP::Crypto - randomness and the primitives that the HAP
# protocol needs.
#
# Every method is a class method. The module keeps no state and never
# logs. A programming error dies; there is no partial result and no
# quiet fallback, because a caller cannot recover from a key that is
# not a key.
#
# random_bytes uses core Perl only. The signature, key-agreement and
# AEAD groups load their Crypt::* library on first use, so a program
# that never signs anything never needs them installed.
#
# The read from /dev/urandom is a documented exception to the sans-IO
# rule of Protocol::HAP: key material must come from the kernel.

use constant URANDOM_PATH => '/dev/urandom';

# Which library each function group needs. The failure message names
# the module and the group, so an operator knows what to install and
# why.
my %GROUP = (
	ed25519 => 'Crypt::Ed25519',
	x25519  => 'Crypt::Curve25519',
	hkdf    => 'Crypt::KeyDerivation',
	aead    => 'Crypt::AuthEnc::ChaCha20Poly1305',
);

my %loaded;

# $class->random_bytes($length):
#	Return $length bytes from /dev/urandom.
#
#	The method dies when the device does not open, and dies on a
#	short read. Neither one has a recovery: a caller that continues
#	with fewer bytes than it asked for builds a key with a known
#	prefix.
sub random_bytes ( $class, $length )
{
	die 'random_bytes needs a positive length'
	    unless defined $length && $length > 0;

	open my $fh, '<', URANDOM_PATH
	    or die 'Cannot open ' . URANDOM_PATH . ": $!";
	binmode $fh;

	my $bytes = '';
	while ( length($bytes) < $length ) {
		my $n = read $fh, my $chunk, $length - length($bytes);
		if ( !defined $n ) {
			close $fh;
			die 'Cannot read ' . URANDOM_PATH . ": $!";
		}
		if ( $n == 0 ) {
			close $fh;
			die 'Short read from '
			    . URANDOM_PATH
			    . ': got '
			    . length($bytes)
			    . ", expected $length";
		}
		$bytes .= $chunk;
	}
	close $fh;

	return $bytes;
}

# $class->preload:
#	Load every Crypt::* library now. A daemon that pledges without
#	prot_exec must call this before it pledges: a lazy require
#	after the pledge dlopens a shared object, and that kills the
#	process.
#
#	The method returns the number of libraries it loaded. It dies
#	when one is missing, because a daemon that discovers a missing
#	library after the pledge cannot report it.
sub preload ($class)
{
	my $count = 0;
	for my $group ( sort keys %GROUP ) {
		$count++ unless $loaded{$group};
		_load($group);
	}

	return $count;
}

# $class->ed25519_keypair:
#	Return ($secret_key, $public_key) for a fresh Ed25519 identity.
sub ed25519_keypair ($class)
{
	_load('ed25519');

	my ( $public, $secret ) = Crypt::Ed25519::generate_keypair();

	return ( $secret, $public );
}

# $class->ed25519_sign($message, $secret_key, $public_key):
#	Return the 64-byte signature over $message.
sub ed25519_sign ( $class, $message, $secret_key, $public_key )
{
	_load('ed25519');

	return Crypt::Ed25519::sign( $message, $public_key, $secret_key );
}

# $class->ed25519_verify($signature, $message, $public_key):
#	Report if the signature is valid for the message and the key.
sub ed25519_verify ( $class, $signature, $message, $public_key )
{
	_load('ed25519');

	return Crypt::Ed25519::verify( $message, $public_key, $signature );
}

# $class->x25519_keypair:
#	Return ($secret_key, $public_key) for a fresh X25519 exchange.
sub x25519_keypair ($class)
{
	_load('x25519');

	my $secret =
	    Crypt::Curve25519::curve25519_secret_key(
		$class->random_bytes(32) );
	my $public = Crypt::Curve25519::curve25519_public_key($secret);

	return ( $secret, $public );
}

# $class->x25519_shared_secret($our_secret, $their_public):
#	Return the 32-byte shared secret of the exchange.
sub x25519_shared_secret ( $class, $our_secret, $their_public )
{
	_load('x25519');

	return Crypt::Curve25519::curve25519_shared_secret( $our_secret,
		$their_public );
}

# $class->hkdf_sha512($ikm, $salt, $info, $length):
#	Derive $length bytes with HKDF over SHA-512.
sub hkdf_sha512 ( $class, $ikm, $salt, $info, $length )
{
	_load('hkdf');

	return Crypt::KeyDerivation::hkdf( $ikm, $salt, 'SHA512', $length,
		$info );
}

# $class->chacha20poly1305_encrypt($key, $nonce, $plaintext, $aad):
#	Return ($ciphertext, $tag).
sub chacha20poly1305_encrypt ( $class, $key, $nonce, $plaintext, $aad = '' )
{
	_load('aead');

	my ( $ciphertext, $tag ) =
	    Crypt::AuthEnc::ChaCha20Poly1305::chacha20poly1305_encrypt_authenticate(
		$key, $nonce, $aad, $plaintext );

	return ( $ciphertext, $tag );
}

# $class->chacha20poly1305_decrypt($key, $nonce, $ciphertext, $tag, $aad):
#	Return the plaintext, or undef when the tag does not verify. A
#	failed verification is the normal answer for a forged or
#	damaged message, so it is not fatal.
sub chacha20poly1305_decrypt ( $class, $key, $nonce, $ciphertext, $tag,
	$aad = '' )
{
	_load('aead');

	return
	    Crypt::AuthEnc::ChaCha20Poly1305::chacha20poly1305_decrypt_verify(
		$key, $nonce, $aad, $ciphertext, $tag );
}

# _load($group):
#	Load the library that a function group needs, once. The failure
#	names the module and the group, because "Can't locate
#	Crypt/Ed25519.pm in @INC" tells an operator nothing about which
#	feature stopped working.
sub _load ($group)
{
	return 1 if $loaded{$group};

	my $module = $GROUP{$group} // die "Unknown crypto group: $group";
	my $path   = $module =~ s{::}{/}gr . '.pm';

	eval { require $path; 1 }
	    or die
	    "Protocol::HAP::Crypto needs $module for $group operations: $@";

	$loaded{$group} = 1;

	return 1;
}

1;
