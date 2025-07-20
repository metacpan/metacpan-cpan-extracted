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

  my $sign = Crypt::Sodium::XS::OO::sign->new(primitive => 'ed25519');
  my $sign = Crypt::Sodium::XS->sign;

Returns a new secretstream object for the given primitive. If not given, the
default primitive is C<default>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $sign->primitive;
  $sign->primitive('ed25519');

Gets or sets the primitive used for all operations by this object. Note this
can be C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = Crypt::Sodium::XS::OO::sign->primitives;
  my @primitives = $sign->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $sign->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 detached

  my $signature = $sign->detached($message, $my_secret_key);

C<$message> is the message to sign.

C<$my_secret_key> is a secret key used to sign the message. It must be
L</SECRETKEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns a message signature of L</BYTES> bytes.

=head2 init

  my $multipart = $sign->init($flags);

C<$flags> is optional. It is the flags used for the multipart sign protected
memory object. See L<Crypt::Sodium::XS::ProtMem>.

Returns a multipart sign object. See L<MULTI-PART INTERFACE>.

=head2 keypair

  my ($public_key, $secret_key) = $sign->keypair($seed, $flags);

C<$seed> is optional. It must be L</SEEDBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Using the same seed will generate the same key
pair, so it must be kept confidential. If omitted, a key pair is randomly
generated.

Returns a public key of L</PUBLICKEYBYTES> bytes and a
L<Crypt::Sodium::XS::MemVault>: a secret key of L</SECRETKEYBYTES> bytes.

=head2 open

  my $message = $sign->open($signed_message, $their_public_key);

Croaks on invalid signature.

C<$signed_message> is the combined message and signature from an earlier call
to L</sign>.

C<$their_public_key> is the public key used to authenticate the message
signature. It must be L</PUBLICKEYBYTES> bytes.

Returns the message content without the signature.

=head2 sign

  my $signed_message = $sign->sign($message, $my_secret_key);

C<$message> is the message to sign. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$my_secret_key> is a secret key used to sign the message. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the combined message and signature.

=head2 verify

  my $is_valid = $sign->verify($message, $signature, $their_public_key);

C<$message> is the message data to validate against the signature and key.

C<$signature> is the detached message signature from an earlier call to
L</detached>. It must be L</BYTES> bytes.

C<$their_public_key> is the public key used to authenticate the message
signature. It must be L</PUBLICKEYBYTES> bytes.

Returns the true if the signature is valid for the message and public key,
false otherwise.

=head2 sk_to_pk

  my $public_key = $sign->sk_to_pk($secret_key);

C<$secret_key> is a secret key. It must be L</SECRETKEYBYTES> bytes. It may be
a L<Crypt::Sodium::XS::MemVault>.

Returns the public key of L</PUBLICKEYBYTES> bytes derived from the secret key.

=head2 sk_to_seed

  my $seed = $sign->sk_to_seed($secret_key, $flags);

C<$secret_key> is a secret key. It must be L</SECRETKEYBYTES> bytes. It may be
a L<Crypt::Sodium::XS::MemVault>.

Returns a L<Crypt::Sodium::XS::MemVault>: a seed which can be used to recreate
the same secret (and public) key with L</keypair>.

=head2 BYTES

  my $signature_size = $sign->BYTES;

Returns the size, in bytes, of a signature.

=head2 MESSAGEBYTES_MAX

  my $message_max_size = $sign->MESSAGEBYTES_MAX;

Returns the size, in bytes, of the maximum size of any message to be encrypted.

=head2 PUBLICKEYBYTES

  my $public_key_size = $sign->PUBLICKEYBYTES;

Returns the size, in bytes, of a public key.

=head2 SECRETKEYBYTES

  my $secret_key_size = $sign->SECRETKEYBYTES;

Returns the size, in bytes, of a secret key.

=head2 SEEDBYTES

  my $seed_size = $sign->SEEDBYTES;

Returns the size, in bytes, of a seed used by L</keypair>.

=head1 ed25519 to curve25519 METHODS

For the ed25519 primitive only.

Ed25519 keys can be converted to X25519 keys, so that the same key pair can be
used both for authenticated encryption (L<Crypt::Sodium::XS::box>) and for
signatures (L<Crypt::Sodium::XS::sign>).

If you can afford it, using distinct keys for signing and for encryption is
still highly recommended.

The following methods perform these conversions:

=head2 pk_to_curve25519

  my $curve_public_key = $sign->pk_to_curve25519($public_key);

C<$public_key> is a public key. It must be L</PUBLICKEYBYTES> bytes.

Returns the x25519 public key.

=head2 sk_to_curve25519

  my $curve_secret_key = $sign->pk_to_curve25519($secret_key, $flags);

C<$secret_key> is a secret key. It must be L</SECRETKEYBYTES> bytes. It may be
a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$curve_secret_key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the x25519 secret key.

=head2 to_curve25519

  my ($curve_pk, $curve_sk) 
    = $sign->to_curve25519($public_key, $secret_key, $flags);

C<$public_key> is a public key. It must be L</PUBLICKEYBYTES> bytes.

C<$secret_key> is a secret key. It must be L</SECRETKEYBYTES> bytes. It may be
a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$curve_secret_key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns the x25519 public key and a L<Crypt::Sodium::XS::MemVault>: the x25519
secret key.

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

=head2 clone

  my $multipart_copy = $multipart->clone;

Returns a cloned copy of the multipart sign object, duplicating its internal
state.

=head2 final_sign

  my $signature = $multipart->final_sign($my_secret_key);

C<$my_secret_key> is a secret key used to sign the data. It must be
L</SECRETKEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the detached signature of L</BYTES> bytes.

=head2 final_verify

  my $is_valid = $multipart->final_verify($signature, $their_public_key);

C<$signature> is the detached signature to validate against signed data and the
public key. It must be L</BYTES> bytes.

C<$their_public_key> is the public key used to authenticate the signature. It
must be L</PUBLICKEYBYTES> bytes.

=head2 update

  $multipart->update(@messages);

Adds all given arguments (stringified) to signed data. Any argument may be a
L<Crypt::Sodium::XS::MemVault>.

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
