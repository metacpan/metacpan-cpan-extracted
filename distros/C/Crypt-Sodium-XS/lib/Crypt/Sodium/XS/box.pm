package Crypt::Sodium::XS::box;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  BEFORENMBYTES
  MACBYTES
  MESSAGEBYTES_MAX
  NONCEBYTES
  PUBLICKEYBYTES
  SEALBYTES
  SECRETKEYBYTES
  SEEDBYTES
);

my @bases = qw(
  beforenm
  decrypt
  decrypt_afternm
  decrypt_detached
  decrypt_detached_afternm
  encrypt
  encrypt_detached
  encrypt_afternm
  encrypt_detached_afternm
  keypair
  nonce
  seal_encrypt
  seal_decrypt
);

my $default = [
  (map { "box_$_" } @bases),
  (map { "box_$_" } @constant_bases, "PRIMITIVE"),
];
my $curve25519xchacha20poly1305 = [
  (map { "box_curve25519xchacha20poly1305_$_" } @bases),
  (map { "box_curve25519xchacha20poly1305_$_" } @constant_bases),
];
my $curve25519xsalsa20poly1305 = [
  (map { "box_curve25519xsalsa20poly1305_$_" } @bases),
  (map { "box_curve25519xsalsa20poly1305_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all =>
    [ @$default, @$curve25519xchacha20poly1305, @$curve25519xsalsa20poly1305 ],
  default => $default,
  curve25519xchacha20poly1305 => $curve25519xchacha20poly1305,
  curve25519xsalsa20poly1305 => $curve25519xsalsa20poly1305,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::box - Asymmetric (public/secret key) authenticated
encryption

=head1 SYNOPSIS

  use Crypt::Sodium::XS::box ":default";
  use Crypt::Sodium::XS::Util "sodium_increment";

  my ($pk, $sk) = box_keypair();
  my ($pk2, $sk2) = box_keypair();
  my $nonce = box_nonce();

  my $ct = box_encrypt("hello", $nonce, $pk2, $sk);
  my $pt = box_decrypt($ct, $nonce, $pk, $sk2);
  # $pt is now "hello" (MemVault)

  $nonce = sodium_increment($nonce);
  ($ct, my $tag) = box_encrypt_detached("world", $nonce, $pk, $sk2);
  $pt = box_decrypt_detached($ct, $tag, $nonce, $pk2, $sk);
  # $pt is now "world" (MemVault)

  my $precalc1 = box_beforenm($pk2, $sk);
  my $precalc2 = box_beforenm($pk, $sk2);
  # $precalc and $precalc2 hold identical derived secret keys

  $nonce = box_nonce();
  $ct = $precalc->encrypt("goodbye", $nonce);
  $pt = $precalc2->decrypt($ct, $nonce);
  # $pt is now "goodbye" (MemVault)

  $ct = box_seal_encrypt("anonymous message", $pk2);
  $pt = box_seal_decrypt($ct, $pk, $sk);

=head1 DESCRIPTION

Using public-key authenticated encryption, Alice can encrypt a confidential
message specifically for Bob, using Bob's public key.

Based on Bob's public key, Alice can compute a shared secret key. Using Alice's
public key and his secret key, Bob can compute the exact same shared secret
key. That shared secret key can be used to verify that the encrypted message
was not tampered with, before eventually decrypting it.

In order to send messages to Bob, Alice only needs Bob's public key. Bob should
never ever share his secret key (not even with Alice).

For verification and decryption, Bob only needs Alice's public key, the nonce
and the ciphertext. Alice should never ever share her secret key either, even
with Bob.

Bob can reply to Alice using the same system, without having to generate a
distinct key pair.  The nonce doesn't have to be confidential, but it should be
used with just one invocation of L</box_encrypt> for a particular pair of
public and secret keys.

One easy way to generate a nonce is to use L</box_nonce>, considering the size
of the nonces the risk of any random collisions is negligible. For some
applications, if you wish to use nonces to detect missing messages or to ignore
replayed messages, it is also acceptable to use a simple incrementing counter
as a nonce. A better alternative is to use the
L<Crypt::Sodium::XS::secretstream> API.

When doing so you must ensure that the same nonce can never be re-used (for
example you may have multiple threads or even hosts generating messages using
the same key pairs).

As stated above, senders can decrypt their own messages, and compute a valid
authentication tag for any messages encrypted with a given shared secret key.
This is generally not an issue for online protocols. If this is not acceptable,
check out L</box_seal_encrypt> and L</box_seal_decrypt>, as well as the
L<Crypt::Sodium::XS::kx>.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<box_E<lt>primitiveE<gt>_*> functions and constants for that primitive. A
C<:all> tag imports everything.

=head2 box_beforenm

=head2 box_E<lt>primitiveE<gt>_beforenm

  my $precalc = box_beforenm($their_public_key, $my_secret_key, $flags);

C<$their_public_key> is the public key used by the precalcuation object. It
must be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key used by the precalculation object. It must
be L</box_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the precalculation protected
memory object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a precalculation box object. This is
useful if you send or receive many messages using the same public key. See
L</PRECALCULATION INTERFACE>.

=head2 box_decrypt

=head2 box_E<lt>primitiveE<gt>_decrypt

  my $plaintext = box_decrypt(
    $ciphertext,
    $nonce,
    $their_public_key,
    $my_secret_key,
    $flags
  );

Croaks on decryption failure.

C<$ciphertext> is the ciphertext to decrypt.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

C<$their_public_key> is the public key used to authenticate the ciphertext. It
must be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key used to decrypt the ciphertext. It must be
L</box_SECRETKEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

B<NOTE>: this is the libsodium function C<crypto_box_open_easy>. Its name is
slightly different for consistency of this API.

=head2 box_decrypt_detached

=head2 box_E<lt>primitiveE<gt>_decrypt_detached

  my $plaintext = box_decrypt_detached(
    $ciphertext,
    $tag,
    $nonce,
    $their_public_key,
    $my_secret_key,
    $flags
  );

Croaks on decryption failure.

C<$ciphertext> is the ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag. It must be L</box_MACBYTES>
bytes.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

C<$their_public_key> is the public key used to authenticate the ciphertext. It
must be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key used to decrypt the ciphertext. It must be
L</box_SECRETKEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

B<NOTE>: this is the libsodium function C<crypto_box_open_detached>. Its name
is slightly different for consistency of this API.

=head2 box_encrypt

=head2 box_E<lt>primitiveE<gt>_encrypt

  my $ciphertext
    = box_encrypt($message, $nonce, $their_public_key, $my_secret_key);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

C<$their_public_key> is the public key used to encrypt the ciphertext. It must
be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key used to authenticate the ciphertext. It
must be L</box_SECRETKEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

Returns the encrypted ciphertext.

B<NOTE>: this is the libsodium function C<crypto_box>. Its name is slightly
different for consistency of this API.

=head2 box_encrypt_detached

=head2 box_E<lt>primitiveE<gt>_encrypt_detached

  my ($ciphertext, $tag)
    = box_encrypt_detached($message, $nonce, $their_public_key, $my_secret_key);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

C<$their_public_key> is the public key used to encrypt the ciphertext. It must
be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key used to authenticate the ciphertext. It
must be L</box_SECRETKEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

Returns the encrypted ciphertext and its authentication tag.

B<NOTE>: this is the libsodium function C<crypto_box_easy_detached>. Its name
is slightly different for consistency of this API.

=head2 box_keypair

=head2 box_E<lt>primitiveE<gt>_keypair

  my ($public_key, $secret_key) = box_keypair($seed, $flags);

C<$seed> is optional. It must be L</box_SEEDBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Using the same seed will generate the same key
pair, so it must be kept confidential. If omitted, a key pair is randomly
generated.

C<$flags> is optional. It is the flags used for the C<$secret_key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a public key of L</box_PUBLICKEYBYTES> bytes and a
L<Crypt::Sodium::XS::MemVault>: the secret key of L</box_SECRETKEYBYTES> bytes.

=head2 box_nonce

=head2 box_E<lt>primitiveE<gt>_nonce

  my $nonce = box_nonce($base);

C<$base> is optional. It must be less than or equal to L</box_NONCEBYTES>
bytes. If not provided, the nonce will be random.

Returns a nonce of L</box_NONCEBYTES> bytes.

=head1 SEALED BOXES

Sealed boxes are designed to anonymously send messages to a recipient given
their public key.

Only the recipient can decrypt these messages using their private key. While
the recipient can verify the integrity of the message, they cannot verify the
identity of the sender.

A message is encrypted using an ephemeral key pair, with the secret key being
erased right after the encryption process.

Without knowing the secret key used for a given message, the sender cannot
decrypt the message later. Furthermore, without additional data, a message
cannot be correlated with the identity of its sender.

=head2 box_seal_decrypt

=head2 box_E<lt>primitiveE<gt>_seal_decrypt

  my $plaintext = \
    box_seal_decrypt($ciphertext, $my_public_key, $my_secret_key, $flags);

Croaks on decryption failure.

C<$ciphertext> is the ciphertext to decrypt.

C<$my_public_key> is the public key used to authenticate the ciphertext. It
must be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key from which the public key is derived. It
must be L</box_SECRETKEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

This function doesn’t require passing the public key of the sender as the
ciphertext already includes this information. It requires passing
C<$my_public_key> as the anonymous sender and recipient public keys are used to
generate a nonce.

B<NOTE>: this is the libsodium function C<crypto_box_seal_open>. Its name is
slightly different for consistency of this API.

=head2 box_seal_encrypt

=head2 box_E<lt>primitiveE<gt>_seal_encrypt

  my $ciphertext = box_seal_encrypt($message, $their_public_key);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$their_public_key> is the public key to which the message is encrypted. It
must be L</box_PUBLICKEYBYTES> bytes.

Returns the combined ciphertext.

The function creates a new key pair for each message and attaches the public
key to the ciphertext. The secret key is overwritten and is not accessible
after this function returns.

B<NOTE>: this is the libsodium function C<crypto_box_seal>. Its name is
slightly different for consistency of this API.

=head1 PRECALCULATION INTERFACE

Applications that send several messages to the same recipient or receive
several messages from the same sender can improve performance by calculating
the shared key only once, via the precalculation interface.

A precalculated box object is created by calling the L</box_beforenm> function.
It is an opaque object which provides the following methods:

=over 4

=item decrypt

  my $plaintext = $precalc->decrypt($ciphertext, $nonce, $flags);

Croaks on decryption failure.

C<$ciphertext> is the ciphertext to decrypt.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

C<$their_public_key> is the public key derived from the secret key used to
encrypt the ciphertext. It must be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key from which was derived the public key used
to encrypt the ciphertext. It must be L</box_SECRETKEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=item decrypt_detached

  my $plaintext = $precalc->decrypt_detached($ciphertext, $tag, $nonce, $flags);

Croaks on decryption failure.

C<$ciphertext> is the ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag. It must be L</box_MACBYTES>
bytes.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

C<$their_public_key> is the public key derived from the secret key used to
encrypt the ciphertext. It must be L</box_PUBLICKEYBYTES> bytes.

C<$my_secret_key> is the secret key from which was derived the public key used
to encrypt the ciphertext. It must be L</box_SECRETKEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=item encrypt

  my $ciphertext = $precalc->encrypt($message, $nonce);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

Returns the encrypted ciphertext.

=item encrypt_detached

  my ($ciphertext, $tag) = $precalc->encrypt($message, $nonce);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</box_NONCEBYTES> bytes.

Returns the encrypted ciphertext and its authentication tag.

=back

=head1 CONSTANTS

=head2 box_PRIMITIVE

  my $default_primitive = box_PRIMITIVE();

Returns the name of the default primitive.

=head2 box_BEFORENMBYTES

=head2 box_E<lt>primitiveE<gt>_BEFORENMBYTES

  my $shared_key_size = box_BEFORENMBYTES();

Returns the size, in bytes, of the pre-calculated state created by
L</box_beforenm>. Not normally needed.

=head2 box_MACBYTES

=head2 box_E<lt>primitiveE<gt>_MACBYTES

  my $tag_size = box_MACBYTES();

Returns the size, in bytes, of a message authentication tag.

The size of a combined (not detached) encrypted ciphertext is message size +
L</box_MACBYTES>.

=head2 box_MESSAGEBYTES_MAX

=head2 box_E<lt>primitiveE<gt>_MESSAGEBYTES_MAX

  my $message_max_size = box_MESSAGEBYTES_MAX();

Returns the size, in bytes, of the maximum size of any message to be encrypted.

=head2 box_NONCEBYTES

=head2 box_E<lt>primitiveE<gt>_NONCEBYTES

  my $nonce_size = box_NONCEBYTES();

Returns the size, in bytes, of a nonce.

=head2 box_PUBLICKEYBYTES

Returns the size, in bytes, of a public key.

=head2 box_E<lt>primitiveE<gt>_PUBLICKEYBYTES

  my $public_key_size = box_PUBLICKEYBYTES();

=head2 box_SEALBYTES

=head2 box_E<lt>primitiveE<gt>_SEALBYTES

  my $seal_size = box_SEALBYTES();

Returns the size, in bytes, of the "seal" attached to a sealed box. The size of
a sealed box is the message size + L</box_SEALBYTES>.

=head2 box_SECRETKEYBYTES

=head2 box_E<lt>primitiveE<gt>_SECRETKEYBYTES

  my $secret_key_size = box_SECRETKEYBYTES();

Returns the size, in bytes, of a private key.

=head2 box_SEEDBYTES

=head2 box_E<lt>primitiveE<gt>_SEEDBYTES

  my $keypair_seed_size = box_SEEDBYTES();

Returns the size, in bytes, of a seed used by L</box_keypair>.

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<box_E<lt>primitiveE<gt>>-prefixed couterparts (e.g.,
box_curve25519xchacha20poly1305_encrypt,
box_curve25519xsalsa20poly1305_SEEDBYTES).

=over 4

=item * curve25519xchacha20poly1305

=item * curve25519xsalsa20poly1305 (default)

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::box>

=item L<https://doc.libsodium.org/public-key_cryptography/authenticated_encryption>

=back

=head1 FEEDBACK

For reporting bugs, giving feedback, submitting patches, etc. please use the
following:

=over 4

=item *

RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Crypt-Sodium-XS>

=item *

IRC channel C<#sodium> on C<irc.perl.org>.

=item *

Email the author directly.

=back

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
