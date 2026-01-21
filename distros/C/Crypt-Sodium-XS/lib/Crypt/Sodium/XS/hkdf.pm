package Crypt::Sodium::XS::hkdf;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(
    BYTES_MAX
    BYTES_MIN
    KEYBYTES
  );

  my @bases = qw(keygen extract expand extract_init);

  my $hkdf_sha256 = [
    (map { "hkdf_sha256_$_" } @bases),
    (map { "hkdf_sha256_$_" } @constant_bases),
  ];
  my $hkdf_sha512 = [
    (map { "hkdf_sha512_$_" } @bases),
    (map { "hkdf_sha512_$_" } @constant_bases),
  ];
  my $features = ['hkdf_available'];

  our %EXPORT_TAGS = (
    all => [ @$features, @$hkdf_sha256, @$hkdf_sha512 ],
    features => $features,
    sha256 => $hkdf_sha256,
    sha512 => $hkdf_sha512,
  );

  our @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

package Crypt::Sodium::XS::OO::hkdf;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  sha256 => {
    BYTES_MAX => \&Crypt::Sodium::XS::hkdf::hkdf_sha256_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::hkdf::hkdf_sha256_BYTES_MIN,
    KEYBYTES => \&Crypt::Sodium::XS::hkdf::hkdf_sha256_KEYBYTES,
    PRIMITIVE => sub { 'hkdf_sha256' },
    extract => \&Crypt::Sodium::XS::hkdf::hkdf_sha256_extract,
    expand => \&Crypt::Sodium::XS::hkdf::hkdf_sha256_expand,
    extract_init => \&Crypt::Sodium::XS::hkdf::hkdf_sha256_extract_init,
    keygen => \&Crypt::Sodium::XS::hkdf::hkdf_sha256_keygen,
  },
  sha512 => {
    BYTES_MAX => \&Crypt::Sodium::XS::hkdf::hkdf_sha512_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::hkdf::hkdf_sha512_BYTES_MIN,
    KEYBYTES => \&Crypt::Sodium::XS::hkdf::hkdf_sha512_KEYBYTES,
    PRIMITIVE => sub { 'hkdf_sha512' },
    extract => \&Crypt::Sodium::XS::hkdf::hkdf_sha512_extract,
    expand => \&Crypt::Sodium::XS::hkdf::hkdf_sha512_expand,
    extract_init => \&Crypt::Sodium::XS::hkdf::hkdf_sha512_extract_init,
    keygen => \&Crypt::Sodium::XS::hkdf::hkdf_sha512_keygen,
  },
);

sub Crypt::Sodium::XS::hkdf::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::hkdf::primitives;

sub available { goto \&Crypt::Sodium::XS::hkdf::hkdf_available }

sub BYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MAX}; }
sub BYTES_MIN { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MIN}; }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub extract { my $self = shift; goto $methods{$self->{primitive}}->{extract}; }
sub expand { my $self = shift; goto $methods{$self->{primitive}}->{expand}; }
sub extract_init { my $self = shift; goto $methods{$self->{primitive}}->{extract_init}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::hkdf - HMAC-based Extract-and-Expand Key Derivation Function

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  use Crypt::Sodium::XS::hkdf ":features";

  die "no hkdf support" unless hkdf_available;

  my $hkdf = Crypt::Sodium::XS->hkdf;

  my $ikm = "any source and length of data with reasonable entropy";
  my $salt = "salt is optional.";

  my $prk = $hkdf->extract($ikm, $salt);

  my $application_key_1 = $hkdf->expand($prk, "application one");
  my $application_key_2 = $hkdf->expand($prk, "application two");

  my $multipart = $hkdf->extract_init($salt);
  $multipart->update("input");
  $multipart->update(" keying material", " added in parts");
  $prk = $multipart->final;
  ...

=head1 DESCRIPTION

B<Note>: Secret keys used to encrypt or sign confidential data have to be
chosen from a very large keyspace. However, passwords are usually short,
human-generated strings, making dictionary attacks practical. If you are
intending to derive keys from a password, see L<Crypt::Sodium::XS::pwhash>
instead.

HKDF (HMAC-based Extract-and-Expand Key Derivation Function) is a key
derivation function used by many standard protocols. It actually includes two
operations:

=over 4

=item extract

This operation absorbs an arbitrary-long sequence of bytes (also known as
input keying material, or IKM) and outputs a fixed-size master key (also known
as PRK), suitable for use with the second function (expand).

=item expand

This operation generates an variable size subkey given a master key (also known
as PRK) and a description of a key (or “context”) to derive from it. That
operation can be repeated with different descriptions in order to derive as
many keys as necessary.

=back

Expand can be performed without extract, if a randomly sampled key of the right
size is already available, such as from L</keygen>.

The generated keys satifsy the typical requirements of keys used for symmetric
cryptography. In particular, they appear to be sampled from a uniform
distribution over the entire range of possible keys. Contexts don’t have to
secret. They just need to be distinct in order to produce distinct keys from
the same master key.

Any L</KEYBYTES> bytes key that appears to be sampled from a uniform
distribution can be used for the PRK. For example, the output of a key exchange
mechanism (such as from L<Crypt::Sodium::XS::kx>) can be used as a master key.
For convenience, the L</keygen> functions create a random PRK. The master key
should remain secret.

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>hkdf> method.

  my $hkdf = Crypt::Sodium::XS->hkdf(primitive => 'sha256');

Returns a new hkdf object. The primitive attribute is required.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::hkdf>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $hkdf->primitive;
  $hkdf->primitive('sha256');

Gets or sets the primitive used for all operations by this object. Must be one
of the primitives listed in L</PRIMITIVES>. For this module there is no
C<default> primitive, and this attribute is always identical to L</PRIMITIVE>.

=head1 METHODS

=head2 available

  my $has_hkdf = $hkdf->available;

Returns true if L<Crypt::Sodium::XS> supports HKDF, false otherwise. HKDF will
only be supported if L<Crypt::Sodium::XS> was built with a new enough (>=
1.0.19) version of libsodium.

=head2 primitives

  my @primitives = $hkdf->primitives;
  my @primitives = Crypt::Sodium::XS::hkdf->primitives;

Returns a list of all supported primitive names.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $hkdf->PRIMITIVE;

Returns the primitive used for all operations by this object. For this module,
always identical to the L</primitive> attribute.

=head2 expand

  my $subkey = $hkdf->expand($prk, $out_len, $context, $flags);

C<$prk> is a PRK (master key). It must be L</KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$out_len> is the size, in bytes, of the subkey output. It must be in the
range of L</BYTES_MIN> to L</BYTES_MAX>, inclusive.

C<$context> is optional. It is an arbitrary-size string, which can be used to
generate distinct subkeys from the same master key.

C<$flags> is optional. It is the flags used for the C<$subkey>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a subkey of the requested size.

=over 4

This function is effectively a standard alternative to
L<Crypt::Sodium::XS::kdf::derive_from_key>. It is slower, but the context can
be of any size.

=back

=head2 extract

  my $prk = $hkdf->extract($ikm, $salt, $flags);

C<$ikm> is the input keying material from which to extract a PRK (master key).

C<$salt> is optional. It can be a public, unique identifier for a protocol or
application. Its purpose is to ensure that distinct keys will be created even
if the input keying material is accidentally reused across protocols.

C<$flags> is optional. It is the flags used for the C<$prk>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a master key of L</KEYBYTES> bytes.

=over 4

A UUID is a decent example of a salt. There is no minimum size.

If input keying material cannot be accidentally reused, using an empty (undef
or empty string) salt is perfectly acceptable. IKM is an arbitrary-long byte
sequence. The bytes don’t have to be sampled from a uniform distribution. It
can be any combination of text and binary data.

But the overall sequence needs to include some entropy.

The resulting PRK will roughly have the same entropy. The extract operation
effectively extracts the entropy and packs it into a fixed-size key, but it
doesn’t add any entropy.

=back

=head2 extract_init

  my $multipart = $hkdf->extract_init($salt, $flags);

C<$salt> is optional. It can be a public, unique identifier for a protocol or
application. Its purpose is to ensure that distinct keys will be created even
if the input keying material is accidentally reused across protocols.

C<$flags> is optional. It is the flags used for the multipart protected memory
object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a multipart hkdf object. See
L</MULTI-PART INTERFACE>.

Also see the notes for L</extract>.

=head2 keygen

  my $prk = $hkdf->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$prk>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a PRK (master key) of L</KEYBYTES>
bytes.

=head2 BYTES_MAX

Returns the maximum size, in bytes, of output from L</expand>.

=head2 BYTES_MIN

Defined by libsodium to be 0.

=head2 KEYBYTES

Returns the size, in bytes, of a secret key (both PRK and subkey).

=head1 MULTI-PART INTERFACE

To extract a pseudorandom key from an arbitrary size of input keying material,
you may wish to use the multi-part interface. A multipart hkdf object is
created by calling the L</extract_init> method with optional salt. Key material
can be added by calling the </update> method of that object as many times as
desired. An output PRK (master key) is generated by calling its L</final>
method. Do not continue to use the object after calling L</final>.

The precalculated hkdf object is an opaque protected memory object which
provides the following methods:

=head2 final

  my $prk = $multipart->final($flags);

C<$flags> is optional. It is the flags used for the C<$prk>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a PRK (master key) of
L</KEYBYTES> bytes.

Once C<final> has been called, the multipart object must not be used further.

=head2 update

  $multipart->update(@key_data);

Adds all given arguments (stringified) to input keying material. Any argument
may be a L<Crypt::Sodium::XS::MemVault>.

=head1 PRIMITIVES

=over 4

=item * sha256

=item * sha512

=back

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead or in addition.

Nothing is exported by default. A C<:features> tag imports the
C<hkdf_available> feature test function. A separate C<:E<lt>primitiveE<gt>>
import tag is provided for each of the primitives listed in L</PRIMITIVES>.
These tags import the C<hkdf_E<lt>primitiveE<gt>_*> functions and constants for
that primitive. A C<:all> tag imports everything.

B<Note>: L<Crypt::Sodium::XS::hkdf>, like libsodium, does not provide generic
functions for HKDF. Only the primitive-specific functions are available, so
there is no C<:default> tag.

B<Note>: in libsodium, HKDF functions are prefixed C<kdf_hkdf_>. In
L<Crypt::Sodium::XS::hkdf>, they are prefixed with only C<hkdf_>.

=head2 hkdf_available

  my $has_hkdf = hkdf_available();
  my $has_hkdf = Crypt::Sodium::XS::hkdf->hkdf_available;

Same as L</available>.

Can be called as a class method.

=head2 hkdf_E<lt>primitiveE<gt>_expand

  my $subkey = hkdf_sha256_expand($prk, $out_len, $context, $flags);

Same as L</expand>.

=head2 hkdf_E<lt>primitiveE<gt>_extract

  my $prk = hkdf_sha256_extract($ikm, $salt, $flags);

Same as L</extract>.

=head2 hkdf_E<lt>primitiveE<gt>_extract_init

  my $multipart = hkdf_sha256_extract_init($salt, $flags);

Same as L</extract_init>.

=head2 hkdf_E<lt>primitiveE<gt>_keygen

  my $prk = hkdf_sha256_keygen($flags);

Same as L</keygen>.

=head1 CONSTANTS

=head2 hkdf_E<lt>primitiveE<gt>_BYTES_MAX

Same as L</BYTES_MAX>.

=head2 hkdf_E<lt>primitiveE<gt>_BYTES_MIN

Same as L</BYTES_MIN>.

=head2 hkdf_E<lt>primitiveE<gt>_KEYBYTES

Same as L</KEYBYTES>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://doc.libsodium.org/key_derivation/hkdf>

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

Copyright (c) 2024 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
