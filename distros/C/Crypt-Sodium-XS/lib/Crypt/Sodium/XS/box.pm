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
  ($ct, my $mac) = box_encrypt_detached("world", $nonce, $pk, $sk2);
  $pt = box_decrypt_detached($ct, $mac, $nonce, $pk2, $sk);
  # $pt is now "world" (MemVault)

  my $precalc1 = box_beforenm($pk2, $sk);
  my $precalc2 = box_beforenm($pk, $sk2);
  # $precalc and $precalc2 hold identical derived secret keys

  $nonce = box_nonce();
  $ct = $precalc->encrypt("goodbye", $nonce, $shared_key);
  $pt = $precalc2->decrypt($ct, $nonce, $shared_key2);
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
constants as documented below. A separate import tag is provided for each of
the primitives listed in L</PRIMITIVES>. For example,
C<:curve25519xchacha20poly1305> imports
C<box_curve25519xchacha20poly1305_decrypt>. You should use at least one import
tag.

=head2 box_beforenm

  my $precalc = box_beforenm($their_public_key, $my_secret_key);

Returns a precalculation box object. This is useful if you send or receive many
messages using the same public key. See L</PRECALCULATION INTERFACE>.

=head2 box_decrypt

  my $plaintext = box_decrypt(
    $ciphertext,
    $mac,
    $nonce,
    $their_public_key,
    $my_secret_key,
    $flags
  );

Croaks on decryption failure.

B<NOTE>: this is the libsodium function C<crypto_box_open_easy>. Its name is
slightly different for consistency of this API.

=head2 box_decrypt_detached

  my ($plaintext, $mac) = box_decrypt(
    $ciphertext,
    $mac,
    $nonce,
    $their_public_key,
    $my_secret_key,
    $flags
  );

Croaks on decryption failure.

B<NOTE>: this is the libsodium function C<crypto_box_open_detached>. Its name
is slightly different for consistency of this API.

=head2 box_encrypt

  my $ciphertext
    = box_encrypt($message, $nonce, $their_public_key, $my_secret_key);

B<NOTE>: this is the libsodium function C<crypto_box>. Its name is slightly
different for consistency of this API.

=head2 box_encrypt_detached

  my ($ciphertext, $mac)
    = box_encrypt_detached($message, $nonce, $their_public_key, $my_secret_key);

B<NOTE>: this is the libsodium function C<crypto_box_easy_detached>. Its name
is slightly different for consistency of this API.

=head2 box_keypair

  my ($public_key, $secret_key) = box_keypair();
  my ($public_key, $secret_key) = box_keypair($seed);

C<$seed> is optional. If provided, it must be L</box_SEEDBYTES> in length.
Using the same seed will generate the same key pair, so it must be kept
confidential. If omitted, a key pair is randomly generated.

=head2 box_nonce

  my $nonce = box_nonce();
  my $nonce = box_nonce($base_nonce);

=head2 box_seal_encrypt

  my $ciphertext = box_seal_encrypt($message, $their_public_key);

B<NOTE>: this is the libsodium function C<crypto_box_seal>. Its name is
slightly different for consistency of this API.

=head2 box_seal_decrypt

  my $plaintext = box_seal($ciphertext, $my_public_key, $my_secret_key, $flags);

Croaks on decryption failure.

B<NOTE>: this is the libsodium function C<crypto_box_seal_open>. Its name is
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

=item decrypt_detached

  my $plaintext = $precalc->decrypt($ciphertext, $mac, $nonce, $flags);

Croaks on decryption failure.

=item encrypt

  my $ciphertext = $precalc->encrypt($plaintext, $nonce);

=item encrypt_detached

  my ($ciphertext, $mac) = $precalc->encrypt($plaintext, $nonce);

=back

=head1 CONSTANTS

=head2 box_PRIMITIVE

  my $default_primitive = box_PRIMITIVE();

=head2 box_BEFORENMBYTES

  my $shared_key_length = box_BEFORENMBYTES();

=head2 box_MACBYTES

  my $mac_length = box_MACBYTES();

=head2 box_MESSAGEBYTES_MAX

  my $message_max_length = box_MESSAGEBYTES_MAX();

=head2 box_NONCEBYTES

  my $nonce_length = box_NONCEBYTES();

=head2 box_PUBLICKEYBYTES

  my $public_key_length = box_PUBLICKEYBYTES();

=head2 box_SEALBYTES

  my $seal_length = box_SEALBYTES();

ciphertext for sealed boxes is message length + seal length.

=head2 box_SECRETKEYBYTES

  my $secret_key_length = box_SECRETKEYBYTES();

=head2 box_SEEDBYTES

  my $keypair_seed_length = box_SEEDBYTES();

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<box_E<lt>primitiveE<gt>>-prefixed couterparts (e.g.,
box_curve25519xchacha20poly1305_encrypt,
box_curve25519xsalsa20poly1305_SEEDBYTES).

=over 4

=item * curve25519xchacha20poly1305

=item * curve25519xsalsa20poly1305

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
