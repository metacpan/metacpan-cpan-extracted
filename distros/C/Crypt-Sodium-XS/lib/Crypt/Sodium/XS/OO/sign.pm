package Crypt::Sodium::XS::OO::sign;
use strict;
use warnings;

use Crypt::Sodium::XS::sign;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES => \&Crypt::Sodium::XS::sign::sign_BYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::sign::sign_MESSAGEBYTES_MAX,
    PRIMITIVE => \&Crypt::Sodium::XS::sign::sign_PRIMITIVE,
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::sign::sign_PUBLICKEYBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::sign::sign_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::sign::sign_SEEDBYTES,
    detached => \&Crypt::Sodium::XS::sign::sign_detached,
    init => \&Crypt::Sodium::XS::sign::sign_init,
    keypair => \&Crypt::Sodium::XS::sign::sign_keypair,
    open => \&Crypt::Sodium::XS::sign::sign_open,
    pk_to_curve25519 => \&Crypt::Sodium::XS::sign::sign_pk_to_curve25519,
    sign => \&Crypt::Sodium::XS::sign::sign,
    sk_to_curve25519 => \&Crypt::Sodium::XS::sign::sign_sk_to_curve25519,
    sk_to_pk => \&Crypt::Sodium::XS::sign::sign_sk_to_pk,
    sk_to_seed => \&Crypt::Sodium::XS::sign::sign_sk_to_seed,
    to_curve25519 => \&Crypt::Sodium::XS::sign::sign_to_curve25519,
    verify => \&Crypt::Sodium::XS::sign::sign_verify,
  },
  ed25519 => {
    BYTES => \&Crypt::Sodium::XS::sign::sign_ed25519_BYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::sign::sign_ed25519_MESSAGEBYTES_MAX,
    PRIMITIVE => sub { 'ed25519' },
    PUBLICKEYBYTES => \&Crypt::Sodium::XS::sign::sign_ed25519_PUBLICKEYBYTES,
    SECRETKEYBYTES => \&Crypt::Sodium::XS::sign::sign_ed25519_SECRETKEYBYTES,
    SEEDBYTES => \&Crypt::Sodium::XS::sign::sign_ed25519_SEEDBYTES,
    detached => \&Crypt::Sodium::XS::sign::sign_ed25519_detached,
    init => \&Crypt::Sodium::XS::sign::sign_ed25519_init,
    keypair => \&Crypt::Sodium::XS::sign::sign_ed25519_keypair,
    open => \&Crypt::Sodium::XS::sign::sign_ed25519_open,
    pk_to_curve25519 => \&Crypt::Sodium::XS::sign::sign_ed25519_pk_to_curve25519,
    sign => \&Crypt::Sodium::XS::sign::sign_ed25519,
    sk_to_curve25519 => \&Crypt::Sodium::XS::sign::sign_ed25519_sk_to_curve25519,
    sk_to_pk => \&Crypt::Sodium::XS::sign::sign_ed25519_sk_to_pk,
    sk_to_seed => \&Crypt::Sodium::XS::sign::sign_ed25519_sk_to_seed,
    to_curve25519 => \&Crypt::Sodium::XS::sign::sign_ed25519_to_curve25519,
    verify => \&Crypt::Sodium::XS::sign::sign_ed25519_verify,
  },
);

sub primitives { keys %methods }

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES}; }
sub MESSAGEBYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{MESSAGEBYTES_MAX}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub PUBLICKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{PUBLICKEYBYTES}; }
sub SECRETKEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SECRETKEYBYTES}; }
sub SEEDBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SEEDBYTES}; }
sub detached { my $self = shift; goto $methods{$self->{primitive}}->{detached}; }
sub init { my $self = shift; goto $methods{$self->{primitive}}->{init}; }
sub keypair { my $self = shift; goto $methods{$self->{primitive}}->{keypair}; }
sub open { my $self = shift; goto $methods{$self->{primitive}}->{open}; }
sub pk_to_curve25519 { my $self = shift; goto $methods{$self->{primitive}}->{pk_to_curve25519}; }
sub sign { my $self = shift; goto $methods{$self->{primitive}}->{sign}; }
sub sk_to_curve25519 { my $self = shift; goto $methods{$self->{primitive}}->{sk_to_curve25519}; }
sub sk_to_pk { my $self = shift; goto $methods{$self->{primitive}}->{sk_to_pk}; }
sub sk_to_seed { my $self = shift; goto $methods{$self->{primitive}}->{sk_to_seed}; }
sub to_curve25519 { my $self = shift; goto $methods{$self->{primitive}}->{to_curve25519}; }
sub verify { my $self = shift; goto $methods{$self->{primitive}}->{verify}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::sign - Asymmetric (public/secret key) signatures and
verification

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  my $sign = Crypt::Sodium::XS->sign;

  my ($pk, $sk) = $sign->keypair;
  my $msg = "this is a message";

  my $signed_message = $sign->sign($msg, $sk);
  die "invalid signature" unless $sign->open($signed_message, $pk);

  my $sig = $sign->detached($msg, $sk);
  die "invalid signature" unless $sign->verify($msg, $sig, $pk);

  my $multipart = $sign->init;
  $multipart->update("this is");
  $multipart->update(" a", " message");
  $sig = $multipart->final_sign($sk);
  $multipart = $sign->init;
  $multipart->update($msg);
  die "invalid signature" unless $multipart->final_verify($sig, $pk);

=head1 DESCRIPTION

With L<Crypt::Sodium::XS::OO::sign>, a signer generates a key pair with:

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

=head1 CONSTRUCTOR

=head2 new

  my $shorthash = Crypt::Sodium::XS::OO::shorthash->new;
  my $shorthash
    = Crypt::Sodium::XS::OO::shorthash->new(primitive => 'siphash24');
  my $shorthash = Crypt::Sodium::XS->shorthash;

Returns a new secretstream object for the given primitive. If not given, the
default primitive is C<default>.

=head1 METHODS

=head2 PRIMITIVE

  my $sign = Crypt::Sodium::XS::OO::sign->new;
  my $default_primitive = $sign->PRIMITIVE;

=head2 BYTES

  my $signature_length = $sign->BYTES;

=head2 MESSAGEBYTES_MAX

  my $message_max_length = $sign->MESSAGEBYTES_MAX;

=head2 PUBLICKEYBYTES

  my $public_key_length = $sign->PUBLICKEYBYTES;

=head2 SECRETKEYBYTES

  my $secret_key_length = $sign->SECRETKEYBYTES;

=head2 SEEDBYTES

  my $seed_length = $sign->SEEDBYTES;

=head2 primitives

  my @primitives = $pwhash->primitives;

Returns a list of all supported primitive names (including 'default').

=head2 detached

  my $signature = $sign->detached($message, $my_secret_key);

=head2 init

  my $multipart = $sign->init;

Returns a multipart sign object. See L<MULTI-PART INTERFACE>.

=head2 keypair

  my ($public_key, $secret_key) = $sign->keypair;
  my ($public_key, $secret_key) = $sign->keypair($seed);

C<$seed> is optional. If provided, it must be L</SEEDBYTES> in length. Using
the same seed will generate the same key pair, so it must be kept confidential.
If omitted, a key pair is randomly generated.

=head2 open

  my $message = $sign->open($signed_message, $their_public_key);

=head2 sign

  my $signed_message = $sign->sign($message, $my_secret_key);

=head2 verify

  my $is_valid = $sign->verify($message, $signature, $their_public_key);

Counterpart to sign_detached.

=head2 sk_to_pk

  my $public_key = $sign->sk_to_pk($secret_key);

Returns the public key from the secret key.

=head2 sk_to_seed

  my $seed = $sign->sk_to_seed($secret_key);

Returns the seed that was used to create the secret key.

=head1 ed25519 to curve25519 METHODS

Ed25519 keys can be converted to X25519 keys, so that the same key pair can be
used both for authenticated encryption (L<Crypt::Sodium::XS::box>) and for
signatures (L<Crypt::Sodium::XS::sign>).

If you can afford it, using distinct keys for signing and for encryption is
still highly recommended.

The following algorithm-specific methods perform these conversions:

=head2 pk_to_curve25519

  my ($public_key, $secret_key) = $sign->keypair;
  my $curve_public_key = $sign->ed25519_pk_to_curve25519($public_key);

=head2 sk_to_curve25519

  my ($public_key, $secret_key) = $sign->keypair;
  my $curve_secret_key = $sign->ed25519_pk_to_curve25519($secret_key);

=head2 to_curve25519

  my ($public_key, $secret_key) = $sign->keypair;
  my ($curve_pk, $curve_sk) $sign->to_curve25519($public_key, $secret_key);

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
multi-part L</Crypt::Sodium::XS::OO::generichash> APIs and sign the 512-bit
output, preferably prefixed by your protocol name (or anything that will make
the hash unique for a given use case).

A multipart sign object is created by calling the L</init> method. Data
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

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::sign>

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
