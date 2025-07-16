package Crypt::Sodium::XS::OO::scalarmult;
use strict;
use warnings;

use Crypt::Sodium::XS::scalarmult;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_BYTES,
    PRIMITIVE => sub { 'x25519' },
    SCALARBYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_SCALARBYTES,
    base => \&Crypt::Sodium::XS::scalarmult::scalarmult_base,
    base_noclamp => sub { die "base_noclamp only available for 'ed25519' primitive" },
    keygen => \&Crypt::Sodium::XS::scalarmult::scalarmult_keygen,
    scalarmult => \&Crypt::Sodium::XS::scalarmult::scalarmult,
    scalarmult_noclamp => sub { die "scalarmult_noclamp only available for 'ed25519' primitive" },
  },
  ed25519 => {
    BYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_ed25519_BYTES,
    PRIMITIVE => sub { 'ed25519' },
    SCALARBYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_ed25519_SCALARBYTES,
    base => \&Crypt::Sodium::XS::scalarmult::scalarmult_ed25519_base,
    base_noclamp => \&Crypt::Sodium::XS::scalarmult::scalarmult_ed25519_base_noclamp,
    keygen => \&Crypt::Sodium::XS::scalarmult::scalarmult_ed25519_keygen,
    scalarmult => \&Crypt::Sodium::XS::scalarmult::scalarmult_ed25519,
    scalarmult_noclamp => \&Crypt::Sodium::XS::scalarmult::scalarmult_ed25519_noclamp,
  },
  Crypt::Sodium::XS::scalarmult::scalarmult_ristretto255_available() ? (
    ristretto255 => {
      BYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_ristretto255_BYTES,
      PRIMITIVE => sub { 'ristretto255' },
      SCALARBYTES => \&Crypt::Sodium::XS::scalarmult::scalarmult_ristretto255_SCALARBYTES,
      base => \&Crypt::Sodium::XS::scalarmult::scalarmult_ristretto255_base,
      base_noclamp => sub { die "base_noclamp only available for 'ed25519' primitive" },
      keygen => \&Crypt::Sodium::XS::scalarmult::scalarmult_ristretto255_keygen,
      scalarmult => \&Crypt::Sodium::XS::scalarmult::scalarmult_ristretto255,
      scalarmult_noclamp => sub { die "scalarmult_noclamp only available for 'ed25519' primitive" },
    },
  ) : (),
);
$methods{x25519} = $methods{default};

sub primitives { keys %methods }

sub ristretto255_available { goto \&Crypt::Sodium::XS::scalarmult::scalarmult_ristretto255_available }

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub SCALARBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SCALARBYTES}; }
sub base { my $self = shift; goto $methods{$self->{primitive}}->{base}; }
sub base_noclamp { my $self = shift; goto $methods{$self->{primitive}}->{base_noclamp}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub scalarmult { my $self = shift; goto $methods{$self->{primitive}}->{scalarmult}; }
sub scalarmult_noclamp { my $self = shift; goto $methods{$self->{primitive}}->{scalarmult_noclamp}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::scalarmult - Point-scalar multiplication over the
edwards25519 curve

=head1 SYNOPSIS

  use Crypt::Sodium::XS 'sodium_random_bytes';
  my $scalarmult = Crypt::Sodium::XS->scalarmult;

  my $keysize = Crypt::Sodium::XS->box->SECRETKEYBYTES;
  my $client_sk = sodium_random_bytes($keysize);
  my $client_pk = $scalarmult->base($client_sk);
  my $server_sk = sodium_random_bytes($keysize);
  my $server_pk = $scalarmult->base($client_sk);

  # !!! do not use output directly for key exchange; use Crypt::Sodium::XS::kx.
  # if you really want to, you can manually do this:

  # client side:
  my $q = $scalarmult->scalarmult($client_sk, $server_pk);
  my $hasher = Crypt::Sodium::XS->generichash->init;
  $hasher->update($q, $client_pk, $server_pk);
  my $client_shared_secret = $hasher->final;

  # server side:
  my $q = $scalarmult->scalarmult($server_sk, $client_pk);
  my $hasher = Crypt::Sodium::XS->generichash->init;
  $hasher->update($q, $client_pk, $server_pk);
  my $server_shared_secret = $hasher->final;

  # $client_shared_secret and $server_shared_secret are now identical keys.

=head1 DESCRIPTION

L<Crypt::Sodium::XS::scalarmult> provides an API to multiply a point on the
edwards25519 curve.

This can be used as a building block to construct key exchange mechanisms, or
more generally to compute a public key from a secret key. For key exchange, you
generally want to use L<Crypt::Sodium::XS::kx> instead.

=head1 CONSTRUCTOR

=head2 new

  my $scalarmult = Crypt::Sodium::XS::OO::scalarmult->new;
  my $pwhash = Crypt::Sodium::XS->scalarmult;

Returns a new scalarmult object.

=head1 METHODS

=head2 BYTES

  my $out_size = $scalarmult->BYTES

=head2 SCALARBYTES

  my $out_size = $scalarmult->SCALARBYTES

=head2 keygen

  my $secret_key = $scalarmult->keygen;

Generates a new random secret key. Returns C<$secret_key> as a
L<Crypt::Sodium::XS::MemVault>.

=head2 base

  my $public_key = $scalarmult->base($secret_key);

Given a user’s C<$secret_key>, return the user’s public key.

Multiplies the base point (x, 4/5) by a scalar C<$secret_key> (clamped) and
returns the Y coordinate of the resulting point.

NOTE: With the ed25519 primitive, a C<$secret_key> of 0 will croak.

=head2 scalarmult

  my $q = $scalarmult->scalarmult($my_secret_key, $their_public_key);

This method can be used to compute a shared secret C<$q> given a user’s
C<$my_secret_key> and another user’s C<$their_public_key>.

NOTE:

C<$q> represents the X coordinate of a point on the curve. As a result, the
number of possible keys is limited to the group size (≈2^252), which is smaller
than the key space.

For this reason, and to mitigate subtle attacks due to the fact many (p, n)
pairs produce the same result, using the output of the multiplication q
directly as a shared key is not recommended.

A better way to compute a shared key is h(q | pk1 | pk2), with pk1 and pk2
being the public keys.

By doing so, each party can prove what exact public key they intended to
perform a key exchange with (for a given public key, 11 other public keys
producing the same shared secret can be trivially computed).

See L</SYNOPSIS> for an example of this.

ed225519 notes (C<$secret_key> is 'n', C<$public_key> is 'p'):

NOTE: With the ed25519 primitive, this function will croak if C<$my_secret_key>
is 0 or if C<$their_public_key> is not on the curve, not on the main subgroup,
is a point of small order, or is not provided in canonical form.

C<$my_secret_key> is “clamped” (the 3 low bits are cleared to make it a
multiple of the cofactor, bit 254 is set and bit 255 is cleared to respect the
original design).

=head1 SCALAR MULTIPLICATION WITHOUT CLAMPING

In order to prevent attacks using small subgroups, the scalarmult functions
above clear lower bits of the scalar (C<$secret_key>). This may be indesirable
to build protocols that requires C<$secret_key> to be invertible.

The noclamp variants of these functions do not clear these bits, and do not set
the high bit either. These variants expect a scalar in the ]0..L[ range.

These methods are only available for the ed25519 primitive.

=head2 scalarmult_ed2551_base_noclamp

=head2 scalarmult_ed2551_noclamp

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::scalarmult>

=item L<https://doc.libsodium.org/advanced/scalar_multiplication>

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

For any security sensitive reports, please email the author directly or contact
privately via IRC.

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
