package Crypt::Sodium::XS::scalarmult;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

# really no primitive-specific anything here, just being consistent.

my @constant_bases = qw(
  BYTES
  SCALARBYTES
);

my @bases = qw(
  keygen
  base
);

my $default = [
  'scalarmult',
  (map { "scalarmult_$_" } @bases),
  (map { "scalarmult_$_" } @constant_bases),
];

my $ed25519 = [
  qw[
    scalarmult_ed25519
    scalarmult_ed25519_base_noclamp
    scalarmult_ed25519_noclamp
  ],
  (map { "scalarmult_ed25519_$_" } @bases),
  (map { "scalarmult_ed25519_$_" } @constant_bases),
];

my $ristretto255 = [
  'scalarmult_ristretto255',
  (map { "scalarmult_ristretto255_$_" } @bases),
  (map { "scalarmult_ristretto255_$_" } @constant_bases),
];

my $features = [
  'scalarmult_ristretto255_available',
];

our %EXPORT_TAGS = (
  all => [ @$default, @$ed25519 ],
  default => $default,
  ed25519 => $ed25519,
  ristretto255 => $ristretto255,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::scalarmult - Point-scalar multiplication on the Curve25519
curve.

=head1 SYNOPSIS

  use Crypt::Sodium::XS::scalarmult ':default';
  use Crypt::Sodium::XS 'sodium_random_bytes';

  my $keysize = Crypt::Sodium::XS->box->SECRETKEYBYTES;
  my $client_sk = sodium_random_bytes($keysize);
  my $client_pk = scalarmult_base($client_sk);
  my $server_sk = sodium_random_bytes($keysize);
  my $server_pk = scalarmult_base($client_sk);

  # !!! do not use output directly as key exchange !!!
  # use Crypt::Sodium::XS::kx instead, or you can extract shared keys of
  # arbitrary size with generichash:

  use Crypt::Sodium::XS::generichash 'generichash_init';

  # client side:
  my $client_shared_secret = scalarmult($client_sk, $server_pk);
  my $hasher = generichash_init();
  $hasher->update($client_shared_secret, $client_pk, $server_pk);
  my $client_shared_key = $hasher->final;

  # server side:
  my $server_shared_secret = scalarmult($server_sk, $client_pk);
  my $hasher = generichash_init();
  $hasher->update($server_shared_secret, $client_pk, $server_pk);
  my $server_shared_key = $hasher->final;

=head1 DESCRIPTION

L<Crypt::Sodium::XS::scalarmult> provides an API to multiply a point on the
Curve25519 curve.

This can be used as a building block to construct key exchange mechanisms, or
more generally to compute a public key from a secret key. For key exchange, you
generally want to use L<Crypt::Sodium::XS::kx> instead.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<scalarmult_E<lt>primitiveE<gt>_*> functions and constants for that
primitive.  A C<:all> tag imports everything.

=head2 scalarmult_base

=head2 scalarmult_E<lt>primitiveE<gt>_base

  my $public_key = scalarmult_base($secret_key);

C<$secret_key> is a secret key. It must be L</scalarmult_SCALARBYTES> bytes. It
may be a L<Crypt::Sodium::XS::MemVault>.

Returns a public key which is L</scalarmult_BYTES> bytes.

Multiplies the base point (x, 4/5) by a scalar C<$secret_key> (clamped) and
returns the Y coordinate of the resulting point.

NOTE: With the ed25519 primitive, a C<$secret_key> of 0 will croak.

=head2 scalarmult

=head2 scalarmult_E<lt>primitiveE<gt>

  my $shared_secret = scalarmult($my_secret_key, $their_public_key);

C<$my_secret_key> is a secret key. It must be L</scalarmult_SCALARBYTES> bytes.
It may be a L<Crypt::Sodium::XS::MemVault>.

C<$their_public_key> is a public key. It must be L</scalarmult_BYTES> bytes.

Returns a L<Crypt::Sodium::XS::MemVault>: a shared secret of
L</scalarmult_SCALARBYTES> bytes.

B<Note> (ed25519):

=over 4

With the ed25519 primitive, this function will croak if C<$my_secret_key>
is 0 or if C<$their_public_key> is not on the curve, not on the main subgroup,
is a point of small order, or is not provided in canonical form.

Also with ed25519, C<$my_secret_key> is “clamped” (the 3 low bits are cleared
to make it a multiple of the cofactor, bit 254 is set and bit 255 is cleared to
respect the original design).

=back

B<Note>:

=over 4

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

=back

=head2 scalarmult_keygen

=head2 scalarmult_E<lt>primitiveE<gt>_keygen

  my $secret_key = scalarmult_keygen();

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of
L</scalarmult_SCALARBYTES> bytes.

=head1 ed25519 SCALAR MULTIPLICATION WITHOUT CLAMPING

This section applies to primitive ed25519 only.

In order to prevent attacks using small subgroups, the scalarmult functions
above clear lower bits of the scalar (C<$secret_key>). This may be indesirable
to build protocols that require C<$secret_key> to be invertible.

The noclamp variants of these functions do not clear these bits, and do not set
the high bit either. These variants expect a scalar in the ]0..L[ range.

These functions are only available for the ed25519 primitive.

=head2 scalarmult_ed25519_base_noclamp

  my $q_noclamp = scalarmult_ed25519_base_noclamp($n);

=head2 scalarmult_ed25519_noclamp

  my $q_noclamp = scalarmult_ed25519_noclamp($n, $p);

=head1 CONTSANTS

L</scalarmult_BYTES> and L</scalarmult_SCALARBYTES> are provided for
consistency, but it is safe to assume that C<scalarmult_BYTES ==
scalarmult_SCALARBYTES>.

=head2 scalarmult_BYTES

=head2 scalarmult_E<lt>primitiveE<gt>_BYTES

  my $public_key_size = scalarmult_BYTES();

Returns the size, in bytes, of a public key.

=head2 scalarmult_SCALARBYTES

=head2 scalarmult_E<lt>primitiveE<gt>_SCALARBYTES

  my $shared_and_secret_key_size = scalarmult_SCALARBYTES();

Returns the size, in bytes, of a shared or secret key.

=head1 PRIMITIVES

All functions have C<scalarmult_E<lt>primitiveE<gt>>-prefixed couterparts (e.g.,
scalarmult_ed25519_base, scalarmult_).

=over 4

=item x25519 (default)

X25519 (ECDH over Curve25519). See L<RFC
7748|https://www.rfc-editor.org/rfc/rfc7748.txt>.

=item ed25519

Low-level edwards25519 curve. Only to be used for creating custom
constructions.

=item ristretto255

Ristretto is a new unified point compression format for curves over
large-characteristic fields, which divides the curve’s cofactor by 4 or 8 at
very little cost of performance, efficiently implementing a prime-order group.

libsodium 1.0.18+ implements ristreto255: ristretto on top of the Curve25519
curve.

Compared to Curve25519 points encoded as their coordinates, ristretto makes it
easier to safely implement protocols originally designed for prime-order
groups.

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::scalarmult>

=item L<https://doc.libsodium.org/advanced/scalar_multiplication>

=item L<https://doc.libsodium.org/advanced/point-arithmetic>

See 'Scalar Multiplication' for ed25519.

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
