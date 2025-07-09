package Crypt::Sodium::XS::OO::box;
use strict;
use warnings;

use Crypt::Sodium::XS::box;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BEFORENMBYTES => \&Crypt::Sodium::XS::box::box_BEFORENMBYTES,
    MACBYTES => \&Crypt::Sodium::XS::box::box_MACBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::box::box_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::box::box_NONCEBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::box::box_PRIMITIVE,
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::box::box_PUBLICKEYBYTES,
    SEALBYTES => \&Crypt::Sodium::XS::box::box_SEALBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::box::box_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::box::box_SEEDBYTES,
    beforenm => \&Crypt::Sodium::XS::box::box_beforenm,
    decrypt => \&Crypt::Sodium::XS::box::box_decrypt,
    decrypt_afternm => \&Crypt::Sodium::XS::box::box_decrypt_afternm,
    decrypt_detached => \&Crypt::Sodium::XS::box::box_decrypt_detached,
    decrypt_detached_afternm => \&Crypt::Sodium::XS::box::box_decrypt_detached_afternm,
    encrypt => \&Crypt::Sodium::XS::box::box_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::box::box_encrypt_detached,
    encrypt_afternm => \&Crypt::Sodium::XS::box::box_encrypt_afternm,
    encrypt_detached_afternm => \&Crypt::Sodium::XS::box::box_encrypt_detached_afternm,
    keypair => \&Crypt::Sodium::XS::box::box_keypair,
    nonce => \&Crypt::Sodium::XS::box::box_nonce,
    seal_encrypt => \&Crypt::Sodium::XS::box::box_seal_encrypt,
    seal_decrypt => \&Crypt::Sodium::XS::box::box_seal_decrypt,
  },
  curve25519xchacha20poly1305 => {
    BEFORENMBYTES => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_BEFORENMBYTES,
    MACBYTES => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_MACBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_NONCEBYTES,
    PRIMITIVE => sub { 'curve25519xchacha20poly1305' },
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_PUBLICKEYBYTES,
    SEALBYTES => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_SEALBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_SEEDBYTES,
    beforenm => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_beforenm,
    decrypt => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_decrypt,
    decrypt_afternm => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_decrypt_afternm,
    decrypt_detached => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_decrypt_detached,
    decrypt_detached_afternm => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_decrypt_detached_afternm,
    encrypt => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_encrypt_detached,
    encrypt_afternm => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_encrypt_afternm,
    encrypt_detached_afternm => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_encrypt_detached_afternm,
    keypair => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_keypair,
    nonce => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_nonce,
    seal_encrypt => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_seal_encrypt,
    seal_decrypt => \&Crypt::Sodium::XS::box::box_curve25519xchacha20poly1305_seal_decrypt,
  },
  curve25519xsalsa20poly1305 => {
    BEFORENMBYTES => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_BEFORENMBYTES,
    MACBYTES => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_MACBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_NONCEBYTES,
    PRIMITIVE => sub { 'curve25519xsalsa20poly1305' },
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_PUBLICKEYBYTES,
    SEALBYTES => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_SEALBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_SEEDBYTES,
    beforenm => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_beforenm,
    decrypt => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_decrypt,
    decrypt_afternm => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_decrypt_afternm,
    decrypt_detached => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_decrypt_detached,
    decrypt_detached_afternm => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_decrypt_detached_afternm,
    encrypt => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_encrypt,
    encrypt_afternm => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_encrypt_afternm,
    encrypt_detached => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_encrypt_detached,
    encrypt_detached_afternm => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_encrypt_detached_afternm,
    keypair => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_keypair,
    nonce => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_nonce,
    seal_encrypt => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_seal_encrypt,
    seal_decrypt => \&Crypt::Sodium::XS::box::box_curve25519xsalsa20poly1305_seal_decrypt,
  },
);

sub primitives { keys %methods }

sub BEFORENMBYTES { my $self = shift; goto $methods{$self->{primitive}}->{BEFORENMBYTES}; }
sub MACBYTES { my $self = shift; goto $methods{$self->{primitive}}->{MACBYTES}; }
sub MESSAGEBYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{MESSAGEBYTES_MAX}; }
sub NONCEBYTES { my $self = shift; goto $methods{$self->{primitive}}->{NONCEBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub PUBLICKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{PUBLICKEYBYTES}; }
sub SEALBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SEALBYTES}; }
sub SECRETKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SECRETKEYBYTES}; }
sub SEEDBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SEEDBYTES}; }
sub beforenm { my $self = shift; goto $methods{$self->{primitive}}->{beforenm}; }
sub decrypt { my $self = shift; goto $methods{$self->{primitive}}->{decrypt}; }
sub decrypt_afternm { my $self = shift; goto $methods{$self->{primitive}}->{decrypt_afternm}; }
sub decrypt_detached { my $self = shift; goto $methods{$self->{primitive}}->{decrypt_detached}; }
sub decrypt_detached_afternm { my $self = shift; goto $methods{$self->{primitive}}->{decrypt_detached_afternm}; }
sub encrypt { my $self = shift; goto $methods{$self->{primitive}}->{encrypt}; }
sub encrypt_afternm { my $self = shift; goto $methods{$self->{primitive}}->{encrypt_afternm}; }
sub encrypt_detached { my $self = shift; goto $methods{$self->{primitive}}->{encrypt_detached}; }
sub encrypt_detached_afternm { my $self = shift; goto $methods{$self->{primitive}}->{encrypt_detached_afternm}; }
sub keypair { my $self = shift; goto $methods{$self->{primitive}}->{keypair}; }
sub nonce { my $self = shift; goto $methods{$self->{primitive}}->{nonce}; }
sub seal_encrypt { my $self = shift; goto $methods{$self->{primitive}}->{seal_encrypt}; }
sub seal_decrypt { my $self = shift; goto $methods{$self->{primitive}}->{seal_decrypt}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::box - Asymmetric (public/secret key) authenticated
encryption

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  use Crypt::Sodium::XS::Util "sodium_increment";

  my $box = Crypt::Sodium::XS->box;

  my ($pk, $sk) = $box->keypair;
  my ($pk2, $sk2) = $box->keypair;
  my $nonce = $box->nonce;

  my $ct = $box->encrypt("hello", $nonce, $pk2, $sk);
  my $pt = $box->decrypt($ct, $nonce, $pk, $sk2);
  # $pt is now "hello" (MemVault)

  $nonce = sodium_increment($nonce);
  ($ct, my $mac) = $box->encrypt_detached("world", $nonce, $pk, $sk2);
  $pt = $box->decrypt_detached($ct, $mac, $nonce, $pk2, $sk);
  # $pt is now "world" (MemVault)

  my $precalc = $box->beforenm($pk2, $sk);
  my $precalc2 = $box->beforenm($pk, $sk2);
  # $precalc and $precalc2 hold identical derived secret keys

  $nonce = $box->nonce();
  $ct = $precalc->encrypt("goodbye", $nonce);
  $pt = $precalc2->decrypt($ct, $nonce);
  # $pt is now "goodbye" (MemVault)

  $ct = box_seal_encrypt("anonymous message", $pk2);
  $pt = box_seal_decrypt($ct, $sk, $pk);

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

=head1 CONSTRUCTOR

=head2 new

  my $box = Crypt::Sodium::XS::OO::box->new;
  my $primitive = 'curve25519xsalsa20poly1305';
  my $box = Crypt::Sodium::XS::OO::box->new(primitive => $primitive);
  my $box = Crypt::Sodium::XS->box;

Returns a new box object for the given primitive. If not given, the default
primitive is C<default>.

=head1 METHODS

=head2 PRIMITIVE

  my $box = Crypt::Sodium::XS->box;
  my $default_primitive = $box->PRIMITIVE;

=head2 BEFORENMBYTES

  my $shared_key_length = $box->BEFORENMBYTES;

=head2 MACBYTES

  my $mac_length = $box->MACBYTES;

=head2 MESSAGEBYTES_MAX

  my $message_max_length = $box->MESSAGEBYTES_MAX;

=head2 NONCEBYTES

  my $nonce_length = $box->NONCEBYTES;

=head2 PUBLICKEYBYTES

  my $public_key_length = $box->PUBLICKEYBYTES;

=head2 SEALBYTES

  my $seal_length = $box->SEALBYTES;

ciphertext for sealed boxes is message length + seal length.

=head2 SECRETKEYBYTES

  my $secret_key_length = $box->SECRETKEYBYTES;

=head2 SEEDBYTES

  my $keypair_seed_length = $box->SEEDBYTES;

=head2 beforenm

  my $precalc = $box->beforenm($their_public_key, $my_secret_key);

Returns a precalculation box object. This is useful if you send or receive many
messages using the same public key. See L</PRECALCULATION INTERFACE>.

=head2 decrypt

  my $plaintext = $box->decrypt(
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

=head2 decrypt_detached

  my ($plaintext, $mac) = $box->decrypt(
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

=head2 encrypt

  my $ciphertext
    = $box->encrypt($message, $nonce, $their_public_key, $my_secret_key);

B<NOTE>: this is the libsodium function C<crypto_box>. Its name is slightly
different for consistency of this API.

=head2 encrypt_detached

  my ($ciphertext, $mac) = $box->encrypt_detached(
    $message,
    $nonce,
    $their_public_key,
    $my_secret_key
  );

B<NOTE>: this is the libsodium function C<crypto_box_easy_detached>. Its name
is slightly different for consistency of this API.

=head2 keypair

  my ($public_key, $secret_key) = $box->keypair;
  my ($public_key, $secret_key) = $box->keypair($seed);

C<$seed> is optional. If provided, it must be L</box_SEEDBYTES> in length.
Using the same seed will generate the same key pair, so it must be kept
confidential. If omitted, a key pair is randomly generated.

=head2 nonce

  my $nonce = $box->nonce;
  my $nonce = $box->nonce($base_nonce);

=head2 seal_encrypt

  my $ciphertext = $box->seal_encrypt($message, $their_public_key);

B<NOTE>: this is the libsodium function C<crypto_box_seal>. Its name is
slightly different for consistency of this API.

=head2 seal_decrypt

  my $plaintext
    = $box->seal($ciphertext, $my_public_key, $my_secret_key, $flags);

Croaks on decryption failure.

B<NOTE>: this is the libsodium function C<crypto_box_seal_open>. Its name is
slightly different for consistency of this API.

=head1 PRECALCULATION INTERFACE

Applications that send several messages to the same recipient or receive
several messages from the same sender can improve performance by calculating
the shared key only once, via the precalculation interface.

A precalculated box object is created by calling the L</beforenm> method. It is
an opaque object which provides the following methods:

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

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::box>

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
