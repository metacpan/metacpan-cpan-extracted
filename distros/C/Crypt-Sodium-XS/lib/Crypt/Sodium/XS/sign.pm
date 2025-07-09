package Crypt::Sodium::XS::sign;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  BYTES
  MESSAGEBYTES_MAX
  PUBLICKEYBYTES
  SECRETKEYBYTES
  SEEDBYTES
);

my @bases = qw(
  sign
  detached
  init
  keypair
  open
  pk_to_curve25519
  sk_to_curve25519
  sk_to_pk
  sk_to_seed
  to_curve25519
  verify
);

my $default = [
  "sign",
  (map { "sign_$_" } @bases),
  (map { "sign_$_" } @constant_bases, "PRIMITIVE"),
];
my $ed25519 = [
  "sign_ed25519",
  (map { "sign_ed25519_$_" } @bases),
  (map { "sign_ed25519_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all => [ @$default, @$ed25519 ],
  default => $default,
  ed25519 => $ed25519,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::sign - Asymmetric (public/secret key) signatures and
verification

=head1 SYNOPSIS

  use Crypt::Sodium::XS::sign ":default";

  my ($pk, $sk) = sign_keypair();
  my $msg = "this is a message";

  my $signed_message = sign($msg, $sk);
  die "invalid signature" unless sign_open($signed_message, $pk);

  my $sig = sign_detached($msg, $sk);
  die "invalid signature" unless sign_verify($msg, $sig, $pk);

  my $multipart = sign_init();
  $multipart->update("this is");
  $multipart->update(" a", " message");
  $sig = $multipart->final_sign($sk);
  $multipart = sign_init();
  $multipart->update($msg);
  die "invalid signature" unless $multipart->final_verify($sig, $pk);

=head1 DESCRIPTION

With L<Crypt::Sodium::XS::sign>, a signer generates a key pair with:

=over 4

=item a secret key

Used to append a signature to any number of messages.

=item a public key

Can be used by anybody to verify that the signature appended to a message was
actually issued by the creator of the public key.

=back

Verifiers need to already know and ultimately trust a public key before
messages signed using it can be verified.

Warning: this is different from authenticated encryption. Appending a signature
does not change the representation of the message itself.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants as documented below. A separate import tag is provided for each of
the primitives listed in L</PRIMITIVES>. For example, C<:ed25519> imports
C<sign_ed25519_open>. You should use at least one import tag.

=head2 sign_detached

  my $signature = sign_detached($message, $my_secret_key);

=head2 sign_init

  my $multipart = sign_init();

Returns a multipart sign object. See L<MULTI-PART INTERFACE>.

=head2 sign_keypair

  my ($public_key, $secret_key) = sign_keypair();
  my ($public_key, $secret_key) = sign_keypair($seed);

C<$seed> is optional. If provided, it must be L</sign_SEEDBYTES> in length.
Using the same seed will generate the same key pair, so it must be kept
confidential. If omitted, a key pair is randomly generated.

=head2 sign_open

  my $message = sign_open($signed_message, $their_public_key);

=head2 sign

  my $signed_message = sign($message, $my_secret_key);

=head2 sign_verify

  my $is_valid = sign_verify($message, $signature, $their_public_key);

Counterpart to sign_detached.

=head2 sign_sk_to_pk

  my $public_key = sign_sk_to_pk($secret_key);

Returns the public key from the secret key.

=head2 sign_sk_to_seed

  my $seed = sign_sk_to_seed($secret_key);

Returns the seed that was used to create the secret key.

=head1 ed25519 to curve25519 FUNCTIONS

Ed25519 keys can be converted to X25519 keys, so that the same key pair can be
used both for authenticated encryption (L<Crypt::Sodium::XS::box>) and for
signatures (L<Crypt::Sodium::XS::sign>).

If you can afford it, using distinct keys for signing and for encryption is
still highly recommended.

The following primitive-specific functions perform these conversions:

=head2 pk_to_curve25519

  my ($public_key, $secret_key) = sign_keypair();
  my $curve_public_key = sign_ed25519_pk_to_curve25519($public_key);

=head2 sk_to_curve25519

  my ($public_key, $secret_key) = sign_keypair();
  my $curve_secret_key = sign_ed25519_pk_to_curve25519($secret_key);

=head2 to_curve25519

  my ($public_key, $secret_key) = sign_keypair();
  my ($curve_pk, $curve_sk) sign_to_curve25519($public_key, $secret_key);

=head1 MULTI-PART INTERFACE

If the message doesn’t fit in memory, then it can be provided as a sequence of
arbitrarily-sized chunks.

This uses the Ed25519ph signature system, which pre-hashes the message. In
other words, what gets signed is not the message itself but its image through a
hash function.

If the message can fit in memory and be supplied as a single chunk, then the
single-part API should be preferred.

Note: Ed25519ph(m) is intentionally not equivalent to Ed25519(SHA512(m)).

Because of this, signatures created with L</sign_detached> cannot be verified
with the multipart interface, and vice versa.

If, for some reason, you need to pre-hash the message yourself, then use the
multi-part L</Crypt::Sodium::XS::generichash> APIs and sign the 512-bit
output, preferably prefixed by your protocol name (or anything that will make
the hash unique for a given use case).

A multipart sign object is created by calling the L</sign_init> method. Data
to be signed or validated is added by calling the L</update> method of that
object as many times as desired. An output signature is generated by calling
its L</final_sign> method with a secret key, or signature verification is
performed by calling L</final_verify>.

The multipart sign object is an opaque object which provides the following
methods:

=head2 update

  $multipart->update($message);
  $multipart->update(@messages);

=head2 clone

  my $multipart_copy = $multipart->clone;

=head2 final_sign

  my $signature = $multipart->final_sign($my_secret_key);

=head2 final_verify

  my $is_valid = $multipart->final_verify($signature, $their_public_key);

=head1 CONSTANTS

=head2 sign_BYTES

  my $signature_length = sign_BYTES();

=head2 sign_MESSAGEBYTES_MAX

  my $message_max_length = sign_MESSAGEBYTES_MAX();

=head2 sign_PUBLICKEYBYTES

  my $public_key_length = sign_PUBLICKEYBYTES();

=head2 sign_SECRETKEYBYTES

  my $secret_key_length = sign_SECRETKEYBYTES();

=head2 sign_SEEDBYTES

  my $seed_length = sign_SEEDBYTES();

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<sign_E<lt>primitiveE<gt>>-prefixed counterparts (e.g., sign_ed25519_verify,
sign_ed25519_BYTES).

NOTE: The multi-part interface uses a deterministic pre-hashing algorithm with
ed25519, which is not the same as simply
C<sign_ed25519(hash_sha512($message))>. This module (unlike libsodium) exposes
it with the consistent sign_ed25519_init name (no "ph").

=over 4

=item * ed25519

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::sign>

=item L<https://doc.libsodium.org/public-key_cryptography/public-key_signatures>

=item L<https://doc.libsodium.org/advanced/ed25519-curve25519>

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
