=head1 NAME

Crypt::Ed25519 - bare-bones Ed25519 public key signing/verification system

=head1 SYNOPSIS

 use Crypt::Ed25519; # no symbols exported

 ############################################
 # Ed25519 API - public/private keypair

 # generate a public/private key pair once
 ($pubkey, $privkey) = Crypt::Ed25519::generate_keypair;

 # sign a message
 $signature = Crypt::Ed25519::sign $message, $pubkey, $privkey;

 # verify message
 $valid = Crypt::Ed25519::verify $message, $pubkey, $signature;

 # verify, but croak on failure
 Crypt::Ed25519::verify_croak $message, $pubkey, $signature;

 ############################################
 # EdDSA API - secret key and derived public key

 # generate a secret key
 $secret = Crypt::EdDSA::eddsa_secret_key;

 # derive public key as needed
 $pubkey = Crypt::EdDSA::eddsa_public_key $secret;

 # sign a message
 $signature = Crypt::Ed25519::eddsa_sign $message, $pubkey, $secret;

 # verify message
 $valid = Crypt::Ed25519::eddsa_verify $message, $pubkey, $signature;

 # verify, but croak on failure
 Crypt::Ed25519:eddsa_verify_croak $message, $pubkey, $signature;

 ############################################
 # Key exchange

 # side A:
 ($pubkey_a, $privkey_a) = Crypt::Ed25519::generate_keypair;
 # send $pubkey to side B

 # side B:
 ($pubkey_b, $privkey_b) = Crypt::Ed25519::generate_keypair;
 # send $pubkey to side A

 # side A then calculates their shared secret:
 $shared_secret = Crypt::Ed25519::key_exchange $pubkey_b, $privkey_a;

 # and side B does this:
 $shared_secret = Crypt::Ed25519::key_exchange $pubkey_a, $privkey_b;

 # the generated $shared_secret will be the same - you cna now
 # hash it with hkdf or something else to generate symmetric private keys

=head1 DESCRIPTION

This module implements Ed25519 public key generation, message signing and
verification. It is a pretty bare-bones implementation that implements
the standard Ed25519 variant with SHA512 hash, as well as a slower API
compatible with the upcoming EdDSA RFC.

The security target for Ed25519 is to be equivalent to 3000 bit RSA or
AES-128.

The advantages of Ed25519 over most other signing algorithms are:
small public/private key and signature sizes (<= 64 octets), good key
generation, signing and verification performance, no reliance on random
number generators for signing and by-design immunity against branch or
memory access pattern side-channel attacks.

More detailed praise and other info can be found at
L<http://ed25519.cr.yp.to/index.html>.

=head1 CRYPTOGRAPHY IS HARD

A word of caution: don't use this module unless you really know what you
are doing - even if this module were completely error-free, that still
doesn't mean that every way of using it is correct. When in doubt, it's
best not to design your own cryptographic protocol.

=head1 CONVENTIONS

Public/private/secret keys, messages and signatures are all opaque and
architecture-independent octet strings, and, except for the message, have
fixed lengths.

=cut

package Crypt::Ed25519;

BEGIN {
   $VERSION = 1.05;

   require XSLoader;
   XSLoader::load Crypt::Ed25519::, $VERSION;
}

=head1 Ed25519 API

=over 4

=item ($public_key, $private_key) = Crypt::Ed25519::generate_keypair

Creates and returns a new random public and private key pair. The public
key is always 32 octets, the private key is always 64 octets long.

=item ($public_key, $private_key) = Crypt::Ed25519::generate_keypair $secret_key

Instead of generating a random keypair, generate them from the given
C<$secret_key> (e.g. as returned by C<Crypt::Ed25519::eddsa_secret_key>.
The derivation is deterministic, i.e. a specific C<$secret_key> will
always result in the same keypair.

A secret key is simply a random bit string, so if you have a good source
of key material, you can simply generate 32 octets from it and use this as
your secret key.

=item $signature = Crypt::Ed25519::sign $message, $public_key, $private_key

Generates a signature for the given message using the public and private
keys. The signature is always 64 octets long and deterministic, i.e. it is
always the same for a specific combination of C<$message>, C<$public_key>
and C<$private_key>, i.e. no external source of randomness is required for
signing.

=item $valid = Crypt::Ed25519::verify $message, $public_key, $signature

Checks whether the C<$signature> is valid for the C<$message> and C<$public_ke>.

=item Crypt::Ed25519::verify_croak $message, $public_key, $signature

Same as C<Crypt::Ed25519::verify>, but instead of returning a boolean,
simply croaks with an error message when the signature isn't valid, so you
don't have to think about what the return value really means.

=back

=head1 EdDSA compatible API

The upcoming EdDSA draft RFC uses a slightly different (and slower)
API for Ed25519. This API is provided by the following functions:

=over 4

=item $secret_key = Crypt::Ed25519::eddsa_secret_key

Creates and returns a new secret key, which is always 32 octets
long. The secret key can be used to generate the public key via
C<Crypt::Ed25519::eddsa_public_key> and is not the same as the private key
used in the Ed25519 API.

A secret key is simply a random bit string, so if you have a good source
of key material, you can simply generate 32 octets from it and use this as
your secret key.

=item $public_key = Crypt::Ed25519::eddsa_public_key $secret_key

Takes a secret key generated by C<Crypt::Ed25519::eddsa_secret_key>
and returns the corresponding C<$public_key>. The derivation is
deterministic, i.e. the C<$public_key> generated for a specific
C<$secret_key> is always the same.

This public key corresponds to the public key in the Ed25519 API above.

=item $signature = Crypt::Ed25519::eddsa_sign $message, $public_key, $secret_key

Generates a signature for the given message using the public and secret
keys. Apart from specifying the C<$secret_key>, this function is identical
to C<Crypt::Ed25519::sign>, so everything said about it is true for this
function as well.

Internally, C<Crypt::Ed25519::eddsa_sign> derives the corresponding
private key first and then calls C<Crypt::Ed25519::sign>, so it is always
slower.

=item $valid = Crypt::Ed25519::eddsa_verify $message, $public_key, $signature

=item Crypt::Ed25519::eddsa_verify_croak $message, $public_key, $signature

Really the same as C<Crypt::Ed25519::verify> and
C<Crypt::Ed25519::verify_croak>, i.e. the functions without the C<eddsa_>
prefix. These aliases are provided so it's clear that you are using EdDSA
and not Ed25519 API.

=back

=head1 CONVERTING BETWEEN Ed25519 and EdDSA

The Ed25519 and EdDSA compatible APIs handle keys slightly
differently: The Ed25519 API gives you a public/private key pair, while
EdDSA takes a secret and generates a public key from it.

You can convert an EdDSA secret to an Ed25519 private/public key pair
using C<Crypt::Ed25519::generate_keypair>:

   ($public_key, $private_key) = Crypt::Ed25519::generate_keypair $secret

As such, the EdDSA-style API allows you to store only the secret key and
derive the public key as needed. On the other hand, signing using the
private key is faster than using the secret key, so converting the secret
key to a public/private key pair allows you to sign a small message, or
many messages, faster.

=head1 Key Exchange

As an extension to Ed25519, this module implements a key exchange similar
(But not identical) to Curve25519. For this, both sides generate a keypair
and send their public key to the other side. Then both sides can generate
the same shared secret using this function:

=over

=item $shared_secret = Crypt::Ed25519::key_exchange $other_public_key, $own_private_key

Return the 32 octet shared secret generated from the given public and
private key. See SYNOPSIS for an actual example.

=back

=head1 SUPPORT FOR THE PERL MULTICORE SPECIFICATION
        
This module supports the perl multicore specification
(L<http://perlmulticore.schmorp.de/>) for all operations, although it
makes most sense to use it when signing or verifying longer messages.

=head1 IMPLEMENTATION

This module currently uses "Nightcracker's Ed25519" implementation, which
is unmodified except for some portability fixes and static delcarations,
but the interface is kept implementation-agnostic to allow usage of other
implementations in the future.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/Crypt-Ed25519.html

=cut

1

