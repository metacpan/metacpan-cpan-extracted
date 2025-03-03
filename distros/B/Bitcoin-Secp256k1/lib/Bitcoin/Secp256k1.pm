package Bitcoin::Secp256k1;
$Bitcoin::Secp256k1::VERSION = '0.005';
use v5.10;
use strict;
use warnings;
use Digest::SHA qw(sha256);
use Carp;

# RANDOMNESS SOURCE
# libsecp256k1 needs a source of randomness to randomize context, which
# increases its security. Since it is not 100% required for the library to work
# properly, we try a couple sources first, and may eventually give up with a
# warning.

use constant HAS_CRYPTX => eval { require Crypt::PRNG; 1; };
use constant HAS_BYTES_RANDOM_SECURE => eval { require Bytes::Random::Secure; 1; };

sub _random_bytes
{
	my ($count) = @_;

	if (HAS_CRYPTX) {
		return Crypt::PRNG::random_bytes($count);
	}

	if (HAS_BYTES_RANDOM_SECURE) {
		return Bytes::Random::Secure::random_bytes($count);
	}

	carp
		'Caution: no supported PRNG module is installed. For extra security, please install CryptX or Bytes::Random::Secure';
	return undef;
}

our $FORCED_SCHNORR_AUX_RAND;

sub _schnorr_aux_random
{
	return $FORCED_SCHNORR_AUX_RAND // _random_bytes(32);
}

# LOW LEVEL API
# XS defines constructor, destructor and some general utility methods
# interacting directly with libsecp256k1. All of these methods are private and
# subject to change. They are used internally to deliver high level API below.

require XSLoader;
XSLoader::load('Bitcoin::Secp256k1', $Bitcoin::Secp256k1::VERSION);

# HIGH LEVEL API
# These methods are implemented in Perl and deliver more convenient API to
# interact with. They are stable and public.

sub verify_private_key
{
	my ($self, $private_key) = @_;

	return $self->_verify_privkey($private_key);
}

sub create_public_key
{
	my ($self, $private_key) = @_;

	$self->_create_pubkey($private_key);
	return $self->_pubkey;
}

sub normalize_signature
{
	my ($self, $signature) = @_;

	$self->_signature($signature);
	$self->_normalize;

	return $self->_signature;
}

sub compress_public_key
{
	my ($self, $public_key, $compressed) = @_;
	$compressed //= !!1;

	return $self->_pubkey($public_key, $compressed);
}

sub sign_message
{
	my ($self, $private_key, $message) = @_;

	return $self->sign_digest($private_key, sha256(sha256($message)));
}

sub sign_message_schnorr
{
	my ($self, $private_key, $message) = @_;

	return $self->sign_digest_schnorr($private_key, sha256($message));
}

sub sign_digest
{
	my ($self, $private_key, $digest) = @_;

	$self->_sign($private_key, $digest);
	return $self->_signature;
}

sub sign_digest_schnorr
{
	my ($self, $private_key, $digest) = @_;

	$self->_sign_schnorr($private_key, $digest);
	return $self->_signature_schnorr;
}

sub verify_message
{
	my ($self, $public_key, $signature, $message) = @_;

	return $self->verify_digest($public_key, $signature, sha256(sha256($message)));
}

sub verify_message_schnorr
{
	my ($self, $public_key, $signature, $message) = @_;

	return $self->verify_digest_schnorr($public_key, $signature, sha256($message));
}

sub verify_digest
{
	my ($self, $public_key, $signature, $digest) = @_;

	$self->_pubkey($public_key);
	$self->_signature($signature);

	if ($self->_normalize) {
		carp 'Caution: signature to verify is not normalized';
	}

	return $self->_verify($digest);
}

sub verify_digest_schnorr
{
	my ($self, $public_key, $signature, $digest) = @_;

	$self->_xonly_pubkey($public_key);
	$self->_signature_schnorr($signature);

	return $self->_verify_schnorr($digest);
}

sub negate_public_key
{
	my ($self, $public_key) = @_;

	$self->_pubkey($public_key);
	$self->_pubkey_negate;

	return $self->_pubkey;
}

sub negate_private_key
{
	my ($self, $private_key) = @_;

	return $self->_privkey_negate($private_key);
}

sub xonly_public_key
{
	my ($self, $public_key) = @_;

	$self->_pubkey($public_key);
	$self->_convert_pubkey_xonly;

	return $self->_xonly_pubkey;
}

sub add_public_key
{
	my ($self, $public_key, $tweak) = @_;

	$self->_pubkey($public_key);
	$self->_pubkey_add($tweak);

	return $self->_pubkey;
}

sub add_private_key
{
	my ($self, $private_key, $tweak) = @_;

	return $self->_privkey_add($private_key, $tweak);
}

sub multiply_public_key
{
	my ($self, $public_key, $tweak) = @_;

	$self->_pubkey($public_key);
	$self->_pubkey_mul($tweak);

	return $self->_pubkey;
}

sub multiply_private_key
{
	my ($self, $private_key, $tweak) = @_;

	return $self->_privkey_mul($private_key, $tweak);
}

sub combine_public_keys
{
	my ($self, @public_keys) = @_;

	$self->_clear;
	foreach my $pub (@public_keys) {
		$self->_pubkey($pub);
		$self->_push_pubkey;
	}

	$self->_pubkey_combine;

	return $self->_pubkey;
}

1;

__END__

=head1 NAME

Bitcoin::Secp256k1 - Perl interface to libsecp256k1

=head1 SYNOPSIS

	use Bitcoin::Secp256k1;

	# first, create a context
	my $secp256k1 = Bitcoin::Secp256k1->new;

	# then, use it to perform ECC operations
	my $public_key = $secp256k1->create_public_key($private_key);
	my $signature = $secp256k1->sign_message($private_key, $message);
	my $valid = $secp256k1->verify_message($public_key, $signature, $message);

	# Schnorr signatures are implemented
	my $schnorr_signature = $secp256k1->sign_message_schnorr($private_key, $message);
	my $xonly_public_key = $secp256k1->xonly_public_key($public_key);
	my $valid = $secp256k1->verify_message_schnorr($xonly_public_key, $schnorr_signature, $message);

=head1 DESCRIPTION

This module implements XS routines that allow accessing common elliptic curve
operations on secp256k1 curve using Perl code. It requires
L<libsecp256k1|https://github.com/bitcoin-core/secp256k1> to be installed on
the system, and will try to detect and install it automatically using
L<Alien::libsecp256k1>.

=head1 INTERFACE

=head2 Attributes

None - object is a blessed readonly scalar reference with a memory address of a
C structure. As such, it does not contain any attributes accessible directly
from Perl.

=head2 Methods

=head3 new

	$secp256k1 = Bitcoin::Secp256k1->new()

Object constructor. All methods in this package require this object to work
properly. It accepts no arguments.

=head3 verify_private_key

	$valid = $secp256k1->verify_private_key($private_key)

Checks whether bytestring C<$private_key> is a valid private key. Private key
is valid if its length is exactly C<32> and it is below curve order (when
interpreted as a big-endian integer).

Some methods in this module may die if their private key is not valid, but a
chance of picking an invalid 32-byte private key at random are extremely slim.

=head3 create_public_key

	$public_key = $secp256k1->create_public_key($private_key)

Creates a public key from a bytestring C<$private_key> and returns a bytestring
C<$public_key>. C<$private_key> must have exact length of C<32>.

The public key is always returned in compressed form, use L</compress_public_key> to get uncompressed form.

=head3 normalize_signature

	$signature = $secp256k1->normalize_signature($signature)

Performs signature normalization of C<$signature>, which is in DER encoding (a
bytestring). Returns the normalized signature. Will return the same signature
if it was already in a normalized form.

Signature normalization is important because of Bitcoin protocol rules.
Normally, Bitcoin will reject transactions with malleable signatures. This
module will only emit a warning if you try to verify a signature that is not
normalized.

This method lets you both detect whether the signature was malleable and fix it
to avoid a warning if needed.

=head3 compress_public_key

	$public_key = $secp256k1->compress_public_key($public_key, $want_compressed = !!1)

Changes the compression form of bytestring C<$public_key>. If
C<$want_compressed> is a true value (or omitted / undef), method will return
the key in compressed (default) form. If it is a false value, C<$public_key>
will be in uncompressed form. It accepts keys in both compressed and
uncompressed forms.

While both compressed and uncompressed keys will behave the same during
signature verification, they produce different Bitcoin addresses (because
address is a hashed public key).

=head3 sign_message

	$signature = $secp256k1->sign_message($private_key, $message)

Signs C<$message>, which may be a bytestring of any length, with
C<$private_key>, which must be a bytestring of length C<32>. Returns
DER-encoded C<$signature> as a bytestring.

C<$message> is first hashed with double SHA256 (known an HASH256 in Bitcoin)
before passing it to signing algorithm (which expects length C<32> bytestrings).

This method always produces normalized, deterministic signatures suitable to
use inside a Bitcoin transaction.

=head3 sign_message_schnorr

	$signature = $secp256k1->sign_message_schnorr($private_key, $message)

Signs C<$message>, which may be a bytestring of any length, with
C<$private_key>, which must be a bytestring of length C<32>. Returns
a Schnorr C<$signature> as a bytestring.

C<$message> is first hashed with SHA256 before passing it to signing algorithm.

This signature is not deterministic, since signing with Schnorr uses 32 bytes
of auxiliary randomness as an additional security measure. You can set a fixed
value to be used instead by setting package variable
C<$Bitcoin::Secp256k1::FORCED_SCHNORR_AUX_RAND> to any bytestring of length
C<32>.

=head3 sign_digest

	$signature = $secp256k1->sign_digest($private_key, $message_digest)

Same as L</sign_message>, but it does not perform double SHA256 on its input.
Because of that, C<$message_digest> must be a bytestring of length C<32>.

=head3 sign_digest_schnorr

	$signature = $secp256k1->sign_digest_schnorr($private_key, $message_digest)

Same as L</sign_message_schnorr>, but it does not perform SHA256 on its input.
While Schnorr allows any length message, this method requires
C<$message_digest> to be a bytestring of length C<32>.

=head3 verify_message

	$valid = $secp256k1->verify_message($public_key, $signature, $message)

Verifies C<$signature> (DER-encoded, bytestring) of C<$message> (bytestring of
any length) against C<$public_key> (compressed or uncompressed, bytestring).
Returns true if verification is successful.

C<$message> is first hashed with double SHA256 (known an HASH256 in Bitcoin)
before passing it to verification algorithm (which expects length C<32> bytestrings).

Raises a warning if C<$siganture> is not normalized. It is recommended to
perform signature normalization using L</normalize_signature> first and either
accept or reject malleable signatures explicitly.

=head3 verify_message_schnorr

	$valid = $secp256k1->verify_message_schnorr($xonly_public_key, $signature, $message)

Verifies C<$signature> (Schnorr, bytestring) of C<$message> (bytestring of any
length) against C<$xonly_public_key> (bytestring). Returns true is verification
is successful.

C<$message> is first hashed with SHA256 before passing it to verification
algorithm.

=head3 verify_digest

	$valid = $secp256k1->verify_digest($public_key, $signature, $message_digest)

Same as L</verify_message>, but it does not perform double SHA256 on its input.
Because of that, C<$message_digest> must be a bytestring of length C<32>.

=head3 verify_digest_schnorr

	$valid = $secp256k1->verify_digest_schnorr($xonly_public_key, $signature, $message_digest)

Same as L</verify_message_schnorr>, but it does not perform SHA256 on its
input. While Schnorr allows any length message, this method requires
C<$message_digest> to be a bytestring of length C<32>.

=head3 xonly_public_key

	$xonly_public_key = $secp256k1->xonly_public_key($public_key)

Returns a xonly form of C<$public_key>. This form is used in Taproot.

=head3 negate_private_key

	$negated_private_key = $secp256k1->negated_private_key($private_key)

Negates a private key and returns it.

=head3 negate_public_key

	$negated_public_key = $secp256k1->negate_public_key($public_key)

Negates a public key and returns it.

=head3 add_private_key

	$tweaked = $secp256k1->add_private_key($private_key, $tweak)

Add a C<$tweak> (bytestring of length C<32>) to C<$private_key> (bytestring of
length C<32>). The result is a bytestring containing tweaked private key.

If the arguments or the resulting key are not valid, an exception will be thrown.

=head3 add_public_key

	$tweaked = $secp256k1->add_public_key($public_key, $tweak)

Add a C<$tweak> (bytestring of length C<32>) to C<$public_key> (bytestring with
compressed or uncompressed public key). The result is a bytestring containing
tweaked public key in compressed form.

If the arguments or the resulting key are not valid, an exception will be thrown.

=head3 multiply_private_key

	$tweaked = $secp256k1->multiply_private_key($private_key, $tweak)

Same as L</add_private_key>, but performs multiplication instead of addition.

=head3 multiply_public_key

	$tweaked = $secp256k1->multiply_public_key($public_key, $tweak)

Same as L</add_public_key>, but performs multiplication instead of addition.

=head3 combine_public_keys

	$combined = $secp256k1->combine_public_keys(@pubkeys)

Combines C<@pubkeys> together, returning a new pubkey.

If the arguments or the resulting key are not valid, an exception will be thrown.

=head1 IMPLEMENTATION

The module consists of two layers:

=over

=item

High-level API, which consists of public, stable methods. These methods should
deliver most of the possible use cases for the library, but some paths may not
be covered. All of these methods simply accept and return values without
storing anything inside the object.

=item

Low-level API, which is implemented in XS and private. It interacts directly
with libsecp256k1 and is storing some intermediate state (but never the private
key) in a blessed C structure. It covers all of library's functions which are
valuable in Perl's context. Its existence is only significant to the author and
the contributors.

Notable exceptions are the constructor L</new> and the destructor, which are
also part of the low-level API, yet public.

=back

The module also needs a cryptographically-secure source of pseudo-randomness to
deliver the highest level of security. It will try to obtain it from L<CryptX>
or L<Bytes::Random::Secure>. If none of these modules is installed, a warning
will be issued every time randomness is requested by the internals. The library
will continue to work as intended, but randomization is a security feature
which protects against some types of attacks. Refer to libsecp256k1
documentation for details.

=head2 TODO

This module currently covers most usage paths of the base libsecp256k1 and the
Schnorr module. It currently does not aim to cover every usage path, most
notably signing variable length messages with Schnorr (without digesting
first).

=head1 CAVEATS

Documentation of libsecp256k1 recommends keeping secrets on the stack (not the
heap) and erasing them manually after they are no longer used. This is
impossible in Perl, as it gives programmer no control over memory allocation.
This library does not usually clear the secret key memory by overwriting it
with zeros (unless it explicitly copied the secret to a new buffer). If you
need this level of security, you should probably use libsecp256k1 directly in C
code.

=head1 SEE ALSO

L<Alien::libsecp256k1>

L<Bitcoin::Crypto>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

