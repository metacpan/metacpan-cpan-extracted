package Crypt::Sodium::XS::curve25519;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
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
}

package Crypt::Sodium::XS::OO::curve25519;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  ed25519 => {
    BYTES => \&Crypt::Sodium::XS::curve25519::core_ed25519_BYTES,
    HASHBYTES => sub { die 'HASHBYTES only supported by ristretto255 primitive' },
    NONREDUCEDSCALARBYTES => \&Crypt::Sodium::XS::curve25519::core_ed25519_NONREDUCEDSCALARBYTES,
    PRIMITIVE => sub { 'ed25519' },
    SCALARBYTES => \&Crypt::Sodium::XS::curve25519::core_ed25519_SCALARBYTES,
    UNIFORMBYTES => \&Crypt::Sodium::XS::curve25519::core_ed25519_UNIFORMBYTES,
    add => \&Crypt::Sodium::XS::curve25519::core_ed25519_add,
    from_hash => sub { die 'from_hash only supported by ristretto255 primitive' },
    from_uniform => \&Crypt::Sodium::XS::curve25519::core_ed25519_from_uniform,
    is_valid_point => \&Crypt::Sodium::XS::curve25519::core_ed25519_is_valid_point,
    random => \&Crypt::Sodium::XS::curve25519::core_ed25519_random,
    scalar_add => \&Crypt::Sodium::XS::curve25519::core_ed25519_scalar_add,
    scalar_complement => \&Crypt::Sodium::XS::curve25519::core_ed25519_scalar_complement,
    scalar_mul => \&Crypt::Sodium::XS::curve25519::core_ed25519_scalar_mul,
    scalar_negate => \&Crypt::Sodium::XS::curve25519::core_ed25519_scalar_negate,
    scalar_random => \&Crypt::Sodium::XS::curve25519::core_ed25519_scalar_random,
    scalar_reduce => \&Crypt::Sodium::XS::curve25519::core_ed25519_scalar_reduce,
    scalar_sub => \&Crypt::Sodium::XS::curve25519::core_ed25519_scalar_sub,
    sub => \&Crypt::Sodium::XS::curve25519::core_ed25519_sub,
  },
  Crypt::Sodium::XS::curve25519::core_ristretto255_available() ? (
    ristretto255 => {
      BYTES => \&Crypt::Sodium::XS::curve25519::core_ristretto255_BYTES,
      HASHBYTES => \&Crypt::Sodium::XS::curve25519::core_ristretto255_HASHBYTES,
      NONREDUCEDSCALARBYTES => \&Crypt::Sodium::XS::curve25519::core_ristretto255_NONREDUCEDSCALARBYTES,
      PRIMITIVE => sub { 'ristretto255' },
      SCALARBYTES => \&Crypt::Sodium::XS::curve25519::core_ristretto255_SCALARBYTES,
      UNIFORMBYTES => sub { die 'UNIFORMBYTES only supported by ed25519 primitive' },
      add => \&Crypt::Sodium::XS::curve25519::core_ristretto255_add,
      from_hash => \&Crypt::Sodium::XS::curve25519::core_ristretto255_from_hash,
      from_uniform => sub { die 'from_uniform only supported by ed25519 primitive' },
      is_valid_point => \&Crypt::Sodium::XS::curve25519::core_ristretto255_is_valid_point,
      random => \&Crypt::Sodium::XS::curve25519::core_ristretto255_random,
      scalar_add => \&Crypt::Sodium::XS::curve25519::core_ristretto255_scalar_add,
      scalar_complement => \&Crypt::Sodium::XS::curve25519::core_ristretto255_scalar_complement,
      scalar_mul => \&Crypt::Sodium::XS::curve25519::core_ristretto255_scalar_mul,
      scalar_negate => \&Crypt::Sodium::XS::curve25519::core_ristretto255_scalar_negate,
      scalar_random => \&Crypt::Sodium::XS::curve25519::core_ristretto255_scalar_random,
      scalar_reduce => \&Crypt::Sodium::XS::curve25519::core_ristretto255_scalar_reduce,
      scalar_sub => \&Crypt::Sodium::XS::curve25519::core_ristretto255_scalar_sub,
      sub => \&Crypt::Sodium::XS::curve25519::core_ristretto255_sub,
    },
  ) : (),
);

sub Crypt::Sodium::XS::curve25519::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::curve25519::primitives;

sub ristretto255_available { goto \&Crypt::Sodium::XS::curve25519::core_ristretto255_available }

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES}; }
sub HASHBYTES { my $self = shift; goto $methods{$self->{primitive}}->{HASHBYTES}; }
sub NONREDUCEDSCALARBYTES { my $self = shift; goto $methods{$self->{primitive}}->{NONREDUCEDSCALARBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub SCALARBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SCALARBYTES}; }
sub UNIFORMBYTES { my $self = shift; goto $methods{$self->{primitive}}->{UNIFORMBYTES}; }
sub add { my $self = shift; goto $methods{$self->{primitive}}->{add}; }
sub from_hash { my $self = shift; goto $methods{$self->{primitive}}->{from_hash}; }
sub from_uniform { my $self = shift; goto $methods{$self->{primitive}}->{from_uniform}; }
sub is_valid_point { my $self = shift; goto $methods{$self->{primitive}}->{is_valid_point}; }
sub random { my $self = shift; goto $methods{$self->{primitive}}->{random}; }
sub scalar_add { my $self = shift; goto $methods{$self->{primitive}}->{scalar_add}; }
sub scalar_complement { my $self = shift; goto $methods{$self->{primitive}}->{scalar_complement}; }
sub scalar_mul { my $self = shift; goto $methods{$self->{primitive}}->{scalar_mul}; }
sub scalar_negate { my $self = shift; goto $methods{$self->{primitive}}->{scalar_negate}; }
sub scalar_random { my $self = shift; goto $methods{$self->{primitive}}->{scalar_random}; }
sub scalar_reduce { my $self = shift; goto $methods{$self->{primitive}}->{scalar_reduce}; }
sub scalar_sub { my $self = shift; goto $methods{$self->{primitive}}->{scalar_sub}; }
sub sub { my $self = shift; goto $methods{$self->{primitive}}->{sub}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::curve25519 - Low-level functions over Curve25519

=head1 SYNOPSIS

  # TODO (still)

=head1 DESCRIPTION

L<Crypt::Sodium::XS::curve25519> provides an API to libsodium's low-level core
functions over the Curve25519 curve. These functions are not usually needed,
and must only be used to implement custom constructions.

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>curve25519> method.

  my $curve25519
    = Crypt::Sodium::XS->curve25519(primitive => 'ristretto255');

Returns a new curve25519 object. The primitive attribute is required.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::curve25519>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $curve25519->primitive;
  $curve25519->primitive('ristretto255');

Gets or sets the primitive used for all operations by this object. Must be one
of the primitives listed in L</PRIMITIVES>. For this module there is no
C<default> primitive, and this attribute is always identical to L</PRIMITIVE>.

=head1 METHODS

=head2 ristretto255_available

  my $ristretto255_available = $curve25519->ristretto255_available;

Returns true if the version of libsodium this module was built with had the
ristretto255 primitive available, false otherwise.

=head2 primitives

  my @primitives = $curve25519->primitives;
  my @primitives = Crypt::Sodium::XS::curve25519->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $curve25519->PRIMITIVE;

=head2 add

  my $r = $curve25519->add($p, $q);

Adds the element represented by C<$p> to the element C<$q> and returns the
resulting element.

The function croaks if C<$p> and/or C<$q> are not valid encoded elements.

=head2 is_valid_point

  my $is_valid = $curve25519->is_valid_point($point);

Checks that C<$point> represents a point on the edwards25519 curve, in
canonical form, on the main subgroup, and that the point doesn’t have a small
order. Returns true if so, false otherwise.

=head2 random

  my $point = $curve25519->random;

Returns the representation of a random group element.

=head2 from_uniform

=head2 from_hash

  $curve25519->primitve('ed25519');
  my $vector = sodium_random_bytes($curve25519->UNIFORMBYTES);
  my $point = $curve25519->from_uniform($vector);
  $curve25519->primitive('ristretto255');
  my $vector2 = sodium_random_bytes($curve25519->HASHBYTES);
  my $point2 = $curve25519->from_hash($vector2);

NOTE: Different methods for primitives ed25519 and ristretto255!

Maps a 32 bytes C<$vector> to a point, and returns its compressed
representation.

The point is guaranteed to be on the main subgroup.

This function directly exposes the Elligator 2 map, uses the high bit to set
the sign of the X coordinate, and the resulting point is multiplied by the
cofactor.

=head2 NOTE: Scalar arithmetic over L

The C<scalar_*> methods operate over scalars in the [0..L[ interval, L being
the order of the main subgroup (2^252 +
27742317777372353535851937790883648493).

Non-reduced inputs are expected to be within that interval.

=head2 scalar_add

  my $r = $curve25519->add($p, $q);

Adds the point C<$p> to the point C<$q>.

The function croaks if C<$p> and/or C<$q> are not valid points.

=head2 scalar_complement

  my $comp = $curve25519->scalar_complement($s, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$comp> so that C<$s> + C<$comp> = 1
(mod L).

=head2 scalar_mul

  my $z = $curve25519->scalar_mul($x, $y, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$x> * C<$y> (mod L).

=head2 scalar_negate

  my $neg = $curve25519->scalar_negate($s, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$neg> so that C<$s> + C<$neg> = 0
(mod L).

=head2 scalar_random

  my $r = $curve25519->scalar_random($flags);

Returns a L<Crypt::Sodium::XS::MemVault>: a representation of a random scalar
in the ]0..L[ interval.

A scalar in the [0..L[ interval can also be obtained by reducing a possibly
larger value with L</scalar_reduce>.

=head2 scalar_reduce

  my $r = $curve25519->scalar_reduce($s, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$s> reduced to C<$s> mod L.

Note that C<$s> is much larger than C<$r> (64 bytes vs 32 bytes). Bits of C<$s>
can be left to 0, but the interval C<$s> is sampled from should be at least 317
bits to ensure almost uniformity of C<$r> over L.

=head2 scalar_sub

  my $z = $curve25519->scalar_sub($x, $y, $flags);

Returns a L<Crypt::Sodium::XS::MemVault>: C<$x> - C<$y> (mod L).

=head2 sub

  my $point = $curve25519->sub($p, $q);

Subtracts the point C<$q> from the point C<$p>.

The function croaks if C<$p> and/or C<$q> are not valid points.

=head2 BYTES

  my $element_size = $curve25519->bytes;

Returns the size of points, in bytes.

=head2 SCALARBYTES

  my $scalar_size = $curve25519->SCALARBYTES;

Returns the size of scalars, in bytes.

=head2 UNIFORMBYTES

  my $uniform_input_size = $curve25519->UNIFORMBYTES;

For ed25519 only; returns the size, in bytes, of input to the L</from_uniform>
method.

=head2 HASHBYTES

  my $hash_input_size = $curve25519->HASHBYTES;

For ristretto255 only; returns the size, in bytes, of input to the
L</from_hash> method.

=head1 PRIMITIVES

=over 4

=item * ed25519

=item * ristretto255

Check L</ristretto255_available> to see if this primitive can be used.

=back

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead or in addition.

Nothing is exported by default. A separate C<:E<lt>primitiveE<gt>> import tag
is provided for each of the primitives listed in L</PRIMITIVES>. These tags
import the C<core_E<lt>primitiveE<gt>_*> functions and constants for that
primitive. A C<:all> tag imports everything.

B<Note>: L<Crypt::Sodium::XS::curve25519> does provide generic functions for
curve25519. Only the primitive-specific functions are available, so there is no
C<:default> tag.

B<Note>: Functions are prefixed with C<core_> (not C<curve25519_>) for
consistency with libsodium function names.

=head2 ristretto255_available (function)

  my $has_ristretto255 = ristretto255_available();
  my $ristretto255_available = Crypt::Sodium::XS::curve25519->ristretto255_available;

Same as L</ristretto255_available> (method).

Can be called as a class method.

=head2 core_E<lt>primitiveE<gt>_add

  my $r = core_ed25519_add($p, $q);

Same as L</add>.

=head2 core_E<lt>primitiveE<gt>_is_valid_point

  my $is_valid = core_ed25519_is_valid_point($point);

Same as L</is_valid_point>.

=head2 core_E<lt>primitiveE<gt>_random

  my $point = core_ed25519_random();

Same as L</random>.

=head2 core_ed25519_from_uniform

=head2 core_ristretto255_from_hash

  my $point = core_ed25519_from_uniform($vector);
  my $point2 = core_ristretto255_from_hash($vector2);

Same as L</from_uniform> and L</from_hash>, respectively.

B<Note>: Different functions for primitives ed25519 and ristretto255!

=head2 core_E<lt>primitiveE<gt>_scalar_add

  my $r = core_ed25519_add($p, $q);

Same as L</scalar_add>.

=head2 core_E<lt>primitiveE<gt>_scalar_complement

  my $comp = core_ed25519_scalar_complement($s, $flags);

Same as L</scalar_complement>.

=head2 core_E<lt>primitiveE<gt>_scalar_mul

  my $z = core_ed25519_scalar_mul($x, $y, $flags);

Same as L</scalar_mul>.

=head2 core_E<lt>primitiveE<gt>_scalar_negate

  my $neg = core_ed25519_scalar_negate($s, $flags);

Same as L</scalar_negate>.

=head2 core_E<lt>primitiveE<gt>_scalar_random

  my $r = core_ed25519_scalar_random($flags);

Same as L</scalar_random>.

=head2 core_E<lt>primitiveE<gt>_scalar_reduce

  my $r = core_ed25519_scalar_reduce($s, $flags);

Same as L</scalar_reduce>.

=head2 core_E<lt>primitiveE<gt>_scalar_sub

  my $z = core_ed25519_scalar_sub($x, $y, $flags);

Same as L</scalar_sub>.

=head2 core_E<lt>primitiveE<gt>_sub

  my $r = core_ed25519_sub($p, $q);

Same as L</sub>.

=head1 CONSTANTS

=head2 core_E<lt>primitiveE<gt>_BYTES

  my $element_size = core_ed25519_bytes;

Same as L</BYTES>.

=head2 core_E<lt>primitiveE<gt>_SCALARBYTES

  my $scalar_size = core_ed25519_SCALARBYTES;

Same as L</SCALARBYTES>.

=head2 core_ed25519_UNIFORMBYTES

  my $uniform_input_size = core_ed25519_UNIFORMBYTES;

Same as L</UNIFORMBYTES>.

=head2 core_ristretto255_HASHBYTES

  my $hash_input_size = core_ristretto255_HASHBYTES;

Same as L</HASHBYTES>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::scalarmult>

See this module for point-scalar multiplication with ed25519 and ristretto255.

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
