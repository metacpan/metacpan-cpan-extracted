package Crypt::Sodium::XS::xof;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(BLOCKBYTES DOMAIN_STANDARD STATEBYTES);
  my @bases = qw(init key);

  my $shake128 = [
    'xof_shake128',
    (map { "xof_shake128_$_" } @constant_bases, @bases),
  ];
  my $shake256 = [
    'xof_shake256',
    (map { "xof_shake256_$_" } @constant_bases, @bases),
  ];
  my $turboshake128 = [
    'xof_turboshake128',
    (map { "xof_turboshake128_$_" } @constant_bases, @bases),
  ];
  my $turboshake256 = [
    'xof_turboshake256',
    (map { "xof_turboshake256_$_" } @constant_bases, @bases),
  ];

  our %EXPORT_TAGS = (
    all => [ @$shake128, @$shake256, @$turboshake128, @$turboshake256 ],
    shake128 => $shake128,
    shake256 => $shake256,
    turboshake128 => $turboshake128,
    turboshake256 => $turboshake256,
  );

  our @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

package Crypt::Sodium::XS::OO::xof;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  shake128 => {
    BLOCKBYTES => \&Crypt::Sodium::XS::xof::xof_shake128_BLOCKBYTES,
    DOMAIN_STANDARD => \&Crypt::Sodium::XS::xof::xof_shake128_DOMAIN_STANDARD,
    STATEBYTES => \&Crypt::Sodium::XS::xof::xof_shake128_STATEBYTES,
    init => \&Crypt::Sodium::XS::xof::xof_shake128_init,
    xof => \&Crypt::Sodium::XS::xof::xof_shake128,
    xof_key => \&Crypt::Sodium::XS::xof::xof_shake128_key,
  },
  shake256 => {
    BLOCKBYTES => \&Crypt::Sodium::XS::xof::xof_shake256_BLOCKBYTES,
    DOMAIN_STANDARD => \&Crypt::Sodium::XS::xof::xof_shake256_DOMAIN_STANDARD,
    STATEBYTES => \&Crypt::Sodium::XS::xof::xof_shake256_STATEBYTES,
    init => \&Crypt::Sodium::XS::xof::xof_shake256_init,
    xof => \&Crypt::Sodium::XS::xof::xof_shake256,
    xof_key => \&Crypt::Sodium::XS::xof::xof_shake256_key,
  },
  turboshake128 => {
    BLOCKBYTES => \&Crypt::Sodium::XS::xof::xof_turboshake128_BLOCKBYTES,
    DOMAIN_STANDARD => \&Crypt::Sodium::XS::xof::xof_turboshake128_DOMAIN_STANDARD,
    STATEBYTES => \&Crypt::Sodium::XS::xof::xof_turboshake128_STATEBYTES,
    init => \&Crypt::Sodium::XS::xof::xof_turboshake128_init,
    xof => \&Crypt::Sodium::XS::xof::xof_turboshake128,
    xof_key => \&Crypt::Sodium::XS::xof::xof_turboshake128_key,
  },
  turboshake256 => {
    BLOCKBYTES => \&Crypt::Sodium::XS::xof::xof_turboshake256_BLOCKBYTES,
    DOMAIN_STANDARD => \&Crypt::Sodium::XS::xof::xof_turboshake256_DOMAIN_STANDARD,
    STATEBYTES => \&Crypt::Sodium::XS::xof::xof_turboshake256_STATEBYTES,
    init => \&Crypt::Sodium::XS::xof::xof_turboshake256_init,
    xof => \&Crypt::Sodium::XS::xof::xof_turboshake256,
    xof_key => \&Crypt::Sodium::XS::xof::xof_turboshake256_key,
  },
);

sub Crypt::Sodium::XS::xof::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::xof::primitives;
*available = \&Crypt::Sodium::XS::xof::available;

sub BLOCKBYTES { my $self = shift; goto $methods{$self->{primitive}}->{BLOCKBYTES}; }
sub DOMAIN_STANDARD { my $self = shift; goto $methods{$self->{primitive}}->{DOMAIN_STANDARD}; }
sub PRIMITIVE { my $self = shift; $self->{primitive} }
sub STATEBYTES { my $self = shift; goto $methods{$self->{primitive}}->{STATEBYTES}; }
sub init { my $self = shift; goto $methods{$self->{primitive}}->{init}; }
sub xof { my $self = shift; goto $methods{$self->{primitive}}->{xof}; }
sub xof_key { my $self = shift; goto $methods{$self->{primitive}}->{xof_key}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::xof - Extendable output functions

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  use Crypt::Sodium::XS::xof;
  die "no xof support" unless Crypt::Sodium::XS::xof->available;

  my $xof = Crypt::Sodium::XS->xof(primitive => 'turboshake128');

  # one-shot
  my $out = $xof->xof("foobar", 32);
  print unpack("H*", $out), "\n";
  $out = $xof->xof("foobar", 64);
  print unpack("H*", $out), "\n"; # note first 32 bytes are identical

  # multipart
  my $mp = $xof->init;
  $mp->update(qw(foo bar));
  $mp->update('baz');
  print unpack("H*", $mp->squeeze(32)), "\n" for (1 .. 3);

  # different domain produces unrelated output
  $mp = $xof->init(0x7e);
  $mp->update(qw(foo bar baz));
  print unpack("H*", $mp->squeeze(32)), "\n" for (1 .. 3);

  my $more_output = $mp->squeeze(42);

  # for key derivation, use protected memory objects for output
  my $out_memvault = $mp->squeeze_key(99);

=head1 DESCRIPTION

An extendable output function (XOF) is similar to a hash function, but its
output can be extended to any desired length.

Unlike a hash function where the output size is fixed, a XOF can produce output
of arbitrary length from the same input, making it useful for key derivation,
stream generation, and applications where variable-length output is needed.

libsodium provides two families of XOFs:

=over 4

=item * SHAKE

NIST-standardized XOFs from L<FIPS 202|https://csrc.nist.gov/pubs/fips/202/final>

=item * TurboSHAKE

Faster variants using reduced-round Keccak, standardized in L<RFC
9861|https://www.rfc-editor.org/rfc/rfc9861.html>

=back

XOFs can be used as:

=over 4

=item * Hash functions

Producing fixed-length digests

=item * Key derivation functions

Deriving multiple keys from a seed

=item * Deterministic random generators

Expanding a seed into arbitrary-length output

=item * Domain-separated hashing

Using custom domain separators

=item * Hash-to-curve or hash-to-field

XOFs simplify protocols that need to hash into mathematical structures by
providing arbitrary-length output without awkward padding or multiple hash
calls

=item * Replacing HKDF-Expand

When you have a uniformly random key and need to derive multiple outputs, a XOF
is simpler than HKDF

=back

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>xof> method.

  my $xof = Crypt::Sodium::XS->xof(primitive => 'shake128');

Returns a new xof object. The primitive attribute is required.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::xof>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $xof->primitive;
  $xof->primitive('shake256');

Gets or sets the primitive used for all operations by this object. It must be
one of the primitives listed in L</PRIMITIVES>. For this module there is no
C<default> primitive, and this attribute is always identical to L</PRIMITIVE>.

=head1 METHODS

=head2 available

  my $has_xof = $xof->available;
  my $has_xof = Crypt::Sodium::XS::xof->available;

Returns true if L<Crypt::Sodium::XS> supports XOF, false otherwise. XOF will
only be supported if L<Crypt::Sodium::XS> was built with a new enough version
of libsodium (at least 1.0.21).

Can be called as a class method.

=head2 primitives

  my @primitives = $xof->primitives;
  my @primitives = Crypt::Sodium::XS::xof->primitives;

Returns a list of all supported primitive names.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $xof->PRIMITIVE;

Returns the primitive used for all operations by this object. For this module,
always identical to the L</primitive> attribute.

=head2 init

  my $multipart = $xof->init($domain, $flags);

C<$domain> is optional. It must be an integer value between 1 and 127.
Different values of C<$domain> will create unrelated output, allowing different
applications to use the same underlying XOF without risk of collisions. If not
provided or undefined, the default of L</DOMAIN_STANDARD> is used.

C<$flags> is optional. It is the flags used for the multipart protected memory
object. See L<Crypt::Sodium::XS::ProtMem>.

Returns a multipart xof object. See L</MULTI-PART INTERFACE>.

=head2 xof

  my $out = $xof->xof($msg, $size);

C<$msg> is the input data to the XOF. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$size> is the desired output length, in bytes.

Returns the xof output of C<$size> bytes.

=head2 xof_key

  my $out_mv = $xof->xof_key($msg, $size, $flags);

C<$msg> is the input data to the XOF. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$size> is the desired output length, in bytes.

C<$flags> is optional. It is the flags used for the C<$out>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the xof output of C<$size> bytes.

This is identical to L</xof>, but intended for sensitive output such as
using XOF for key derivation.

=head2 BLOCKBYTES

Returns the internal block size, in bytes. Rarely useful.

=head2 DOMAIN_STANDARD

Returns the default domain value used for L</init>.

=head2 STATEBYTES

Returns the internal hash state size, in bytes. Rarely useful.

=head1 MULTI-PART INTERFACE

The multi-part API allows hashing data provided in chunks, and squeezing output
incrementally.

A multipart xof object is created by calling the L</init> method. Data is
absorbed by one or more calls to the L</update> method of that object. Once all
data has been absorbed, L</squeeze> can be called repeatedly to produce output.

After squeezing begins, no more data can be absorbed into the object.

The xof object is an opaque memory protected object which provides the
following methods:

=head2 clone

  my $mp2 = $multipart->clone;

Returns a cloned copy of the multipart xof object, duplicating its internal
state.

=head2 squeeze

  my $out = $multipart->squeeze($size);

Returns the next C<$size> bytes of output squeezed from absorbed data.

If the output is sensitive (e.g., key derivation), you should prefer
L</squeeze_key> instead.

Do not call L</update> on the same object after calling this method.

=head2 squeeze_key

  my $out_mv = $multipart->squeeze_key($size, $flags);

C<$flags> is optional. It is the flags used for the C<$out_mv>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the next C<$size> bytes of output
squeezed from absorbed data.

This is identical to L</squeeze>, but intended for sensitive output such as
using XOF for key derivation.

Do not call L</update> on the same object after calling this method.

=head2 update

  $multipart->update(@messages);

Adds all given arguments (stringified) to absorbed data. Any argument may be a
L<Crypt::Sodium::XS::MemVault>.

Do not call L</update> on the same object after any data has been output with
L</squeeze> or L</squeeze_key>.

=head1 PRIMITIVES

=over 4

=item * shake128

=item * shake256

=item * turboshake128

=item * turboshake256

=back

SHAKE128 and SHAKE256 are XOFs defined in FIPS 202, based on the Keccak
permutation with 24 rounds.

TurboSHAKE128 and TurboSHAKE256 are faster variants of SHAKE that use 12 rounds
of the Keccak permutation instead of 24. They are roughly twice as fast as
SHAKE while maintaining the same security claims.

TurboSHAKE is the underlying function of KangarooTwelve. Both are standardized
in RFC 9861.

TurboSHAKE128 is the recommended choice for most applications. It offers:

=over 4

=item * Great performance (~2x faster than SHAKE)

=item * 128-bit security, which is more than sufficient for virtually all use cases

=item * Built-in domain separation support

=item * Standardized in RFC 9861

=back

Use a different variant only if you have specific requirements:

=over 4

=item * SHAKE256 or TurboSHAKE256: When you need 256-bit collision resistance

=item * SHAKE128/SHAKE256: When NIST FIPS 202 compliance is mandated

=back

The “128” and “256” in the names refer to security levels, not output sizes.
All variants can produce output of any length.

=head1 SECURITY CONSIDERATIONS

When using a XOF as a hash function (collision resistance matters), the output
should be at least twice the security level. TurboSHAKE128 with a 32-byte
output provides full 128-bit collision resistance. Shorter outputs reduce
collision resistance proportionally: a 16-byte output only provides 64-bit
collision resistance.

When using a XOF for key derivation or as a PRF (preimage resistance matters),
the output length doesn’t affect security as long as you’re using it correctly.
TurboSHAKE128 provides 128-bit preimage resistance regardless of output length.

XOFs differ from hash functions in an important way: for the same input,
requesting different output lengths produces related outputs. Specifically,
shorter outputs are prefixes of longer outputs. If this property is undesirable
for your application, include the intended output length in the input.

The state should not be used after the object has been squeezed unless it is
reinitialized using the init function.

These functions are deterministic: the same input always produces the same
output. They are not suitable for password hashing. For that purpose, use
L<Crypt::Sodium::XS::pwhash>.

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead or in addition.

Nothing is exported by default. A separate C<:E<lt>primitiveE<gt>> import tag
is provided for each of the primitives listed in L</PRIMITIVES>. These tags
import the C<xof_E<lt>primitiveE<gt>_*> functions and constants for that
primitive. A C<:all> tag imports everything.

B<Note>: L<Crypt::Sodium::XS::xof>, like libsodium, does not provide generic
functions for XOF. Only the primitive-specific functions are available, so
there is no C<:default> tag.

=head2 xof_E<lt>primitive<Egt>

  my $out = xof_shake128($msg, $size);

Same as L</xof>.

=head2 xof_E<lt>primitive<Egt>_key

  my $out = xof_shake128_key($msg, $size);

Same as L</xof_key>.

=head1 CONSTANTS

=head2 xof_E<lt>primitiveE<gt>_BLOCKBYTES

Same as L</BLOCKBYTES>.

=head2 xof_E<lt>primitiveE<gt>_DOMAIN_STANDARD

Same as L</DOMAIN_STANDARD>.

=head2 xof_E<lt>primitiveE<gt>_STATEBYTES

Same as L</STATEBYTES>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://libsodium.gitbook.io/doc/hashing/xof>

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

Copyright (c) 2026 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
