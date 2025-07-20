package Crypt::Sodium::XS::curve25519;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  BYTES
  NONREDUCEDSCALARBYTES
  SCALARBYTES
);

my @bases = qw(
  add
  is_valid_point
  random
  scalar_add
  scalar_complement
  scalar_mul
  scalar_negate
  scalar_random
  scalar_reduce
  scalar_sub
  sub
);

my $ed25519 = [
  (map { "core_ed25519_$_" } @bases, "from_uniform"),
  (map { "core_ed25519_$_" } @constant_bases, "UNIFORMBYTES"),
];

my $ristretto255 = [
  (map { "core_ristretto255_$_" } @bases, "from_hash"),
  (map { "core_ristretto255_$_" } @constant_bases, "HASHBYTES"),
];

my $features = [qw[
  core_ristretto255_available
]];

our %EXPORT_TAGS = (
  all => [ @$ed25519, @$ristretto255, @$features, ],
  ed25519 => $ed25519,
  features => $features,
  ristretto255 => $ristretto255,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::curve25519 - Low-level functions over Curve25519

=head1 SYNOPSIS

  # TODO

=head1 DESCRIPTION

L<Crypt::Sodium::XS::curve25519> provides an API to libsodium's low-level core
functions over the Curve25519 curve. These functions are not usually needed,
and must only be used to implement custom constructions.

=head1 FUNCTIONS

Nothing is exported by default. A separate C<:E<lt>primitiveE<gt>> import tag
is provided for each of the primitives listed in L</PRIMITIVES>. These tags
import the C<core_E<lt>primitiveE<gt>_*> functions and constants for that
primitive. A C<:all> tag imports everything.

B<Note>: L<Crypt::Sodium::XS::curve25519> does provide generic functions for
curve25519. Only the primitive-specific functions are available, so there is no
C<:default> tag.

B<Note>: Functions are prefixed with C<core_> (not C<curve25519_>) for
consistency with libsodium function names.

=head2 Scalar arithmetic over L

The C<core_E<lt>primitiveE<gt>_scalar_*> functions operate over scalars in the
[0..L[ interval, L being the order of the main subgroup (2^252 +
27742317777372353535851937790883648493).

Non-reduced inputs are expected to be within that interval.

=head2 ristretto255_available

  my $has_ristretto255 = ristretto255_available();

Returns true if the version of libsodium this module was built with had the
ristretto255 primitive available, false otherwise.

=head2 core_E<lt>primitiveE<gt>_add

  my $r = core_ed25519_add($p, $q);

Adds the element represented by C<$p> to the element C<$q> and returns the
resulting element.

The function croaks if C<$p> and/or C<$q> are not valid encoded elements.

=head2 core_E<lt>primitiveE<gt>_is_valid_point

  my $is_valid = core_ed25519_is_valid_point($point);

Checks that C<$point> represents a point on the edwards25519 curve, in
canonical form, on the main subgroup, and that the point doesn’t have a small
order. Returns true if so, false otherwise.

=head2 core_E<lt>primitiveE<gt>_random

  my $point = core_ed25519_random();

Returns the representation of a random group element.

=head2 core_ed25519_from_uniform

=head2 core_ristretto255_from_hash

  my $vector = sodium_random_bytes(ed25519_UNIFORMBYTES);
  my $point = core_ed25519_from_uniform($vector);
  my $vector2 = sodium_random_bytes(ristretto255_HASHBYTES);
  my $point2 = core_ristretto255_from_hash($vector);

NOTE: Different functions for primitives ed25519 and ristretto255!

Maps a 32 bytes C<$vector> to a point, and returns its compressed
representation.

The point is guaranteed to be on the main subgroup.

This function directly exposes the Elligator 2 map, uses the high bit to set
the sign of the X coordinate, and the resulting point is multiplied by the
cofactor.

=head2 core_E<lt>primitiveE<gt>_scalar_add

  my $r = core_E<lt>primitiveE<gt>_add($p, $q);

Adds the point C<$p> to the point C<$q>.

The function croaks if C<$p> and/or C<$q> are not valid points.

=head2 core_E<lt>primitiveE<gt>_sub

  my $r = core_ed25519_sub($p, $q);

Subtracts the point C<$q> from the point C<$p>.

The function croaks if C<$p> and/or C<$q> are not valid points.

=head2 core_E<lt>primitiveE<gt>_scalar_complement

  my $comp = core_ed25519_scalar_complement($s, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$comp> so that C<$s> + C<$comp> = 1
(mod L).

=head2 core_E<lt>primitiveE<gt>_scalar_mul

  my $z = core_ed25519_scalar_mul($x, $y, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$x> * C<$y> (mod L).

=head2 core_E<lt>primitiveE<gt>_scalar_negate

  my $neg = core_ed25519_scalar_negate($s, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$neg> so that C<$s> + C<$neg> = 0
(mod L).

=head2 core_E<lt>primitiveE<gt>_scalar_random

Returns a L<Crypt::Sodium::XS::MemVault>: a representation of a random scalar
in the ]0..L[ interval.

  my $r = core_E<lt>primitiveE<gt>_scalar_random($flags);

A scalar in the [0..L[ interval can also be obtained by reducing a possibly
larger value with L</core_ed25519_scalar_reduce>.

=head2 core_E<lt>primitiveE<gt>_scalar_reduce

  my $r = core_ed25519_scalar_reduce($s, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$s> reduced to C<$s> mod L.

Note that C<$s> is much larger than C<$r> (64 bytes vs 32 bytes). Bits of C<$s>
can be left to 0, but the interval C<$s> is sampled from should be at least 317
bits to ensure almost uniformity of C<$r> over L.

=head2 core_E<lt>primitiveE<gt>_scalar_sub

  my $z = core_ed25519_scalar_sub($x, $y, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$x> - C<$y> (mod L).

=head1 CONSTANTS

=head2 core_E<lt>primitiveE<gt>_BYTES

  my $element_size = core_ed25519_bytes;

Returns the size of points, in bytes.

=head2 core_E<lt>primitiveE<gt>_SCALARBYTES

  my $scalar_size = core_ed25519_SCALARBYTES;

Returns the size of scalars, in bytes.

=head2 core_ed25519_UNIFORMBYTES

  my $uniform_input_size = core_ed25519_UNIFORMBYTES;

For ed25519 only; returns the size, in bytes, of input to the
L</ed25519_from_uniform> function.

=head2 core_ristretto255_HASHBYTES

  my $hash_input_size = core_ristretto255_HASHBYTES;

For ristretto255 only; returns the size, in bytes, of input to the
L</core_ristretto255_from_hash> function.

=head1 PRIMITIVES

All functions have C<core_E<lt>primitiveE<gt>>-prefixed couterparts (e.g.,
core_ed25519_add, core_ristretto255_SCALARBYTES).

=over 4

=item * ed25519

=item * ristretto255

Check L</ristretto255_available> to see if this primitive can be used.

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::scalarmult>

See this module for point-scalar multiplication with ed25519 and ristretto255.

=item L<Crypt::Sodium::XS::OO::curve25519>

=item L<https://doc.libsodium.org/advanced/scalar_multiplication>

=item L<https://doc.libsodium.org/advanced/point-arithmetic>

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
