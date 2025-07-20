package Crypt::Sodium::XS::hkdf;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

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

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::hkdf - HMAC-based Extract-and-Expand Key Derivation Function

=head1 SYNOPSIS

  use Crypt::Sodium::XS::hkdf ":all";

  my $ikm = "any source and length of data with reasonable entropy";
  my $salt = "salt is optional.";

  my $prk = hkdf_sha256_extract($ikm, $salt);

  my $application_key_1 = hkdf_sha256_expand($prk, "application one");
  my $application_key_2 = hkdf_sha256_expand($prk, "application two");

  my $multipart = hkdf_sha256_extract_init($salt);
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
size is already available, such as from L</hkdf_keygen>.

The generated keys satifsy the typical requirements of keys used for symmetric
cryptography. In particular, they appear to be sampled from a uniform
distribution over the entire range of possible keys. Contexts don’t have to
secret. They just need to be distinct in order to produce distinct keys from
the same master key.

Any L</hkdf_E<lt>primitiveE<gt>_KEYBYTES> bytes key that appears to be sampled
from a uniform distribution can be used for the PRK. For example, the output of
a key exchange mechanism (such as from L<Crypt::Sodium::XS::kx>) can be used as
a master key. For convenience, the L</hkdf_E<lt>primitiveE<gt>_keygen>
functions create a random PRK. The master key should remain secret.

Note that in libsodium, HKDF functions are prefixed C<kdf_hkdf_>. In this
library, they are prefixed with only C<hkdf_>.

=head1 FUNCTIONS

Nothing is exported by default. A C<:features> tag imports the
C<hkdf_available> feature test function. A separate C<:E<lt>primitiveE<gt>>
import tag is provided for each of the primitives listed in L</PRIMITIVES>.
These tags import the C<hkdf_E<lt>primitiveE<gt>_*> functions and constants for
that primitive. A C<:all> tag imports everything.

B<Note>: L<Crypt::Sodium::XS::hkdf>, like libsodium, does not provide generic
functions for HKDF. Only the primitive-specific functions are available, so
there is no C<:default> tag.

=head2 hkdf_available

  my $has_hkdf = hkdf_available();

Returns true if L<Crypt::Sodium::XS> supports HKDF, false otherwise. HKDF will
only be supported if L<Crypt::Sodium::XS> was built with a new enough version
of libsodium headers. A newer dynamic library at runtime will not enable
support.

=head2 hkdf_E<lt>primitiveE<gt>_expand

  my $subkey = hkdf_sha256_expand($prk, $out_len, $context, $flags);

C<$prk> is a PRK (master key). It must be L</hkdf_E<lt>primitive<gt>_KEYBYTES>
bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$out_len> is the size, in bytes, of the subkey output. It must be in the
range of L</hkdf_E<lt>primitiveE<gt>_BYTES_MIN> to
L</hkdf_E<lt>primitiveE<gt>_BYTES_MAX>, inclusive.

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

=head2 hkdf_E<lt>primitiveE<gt>_extract

  my $prk = hkdf_sha256_extract($ikm, $salt, $flags);

C<$ikm> is the input keying material from which to extract a PRK (master key).

C<$salt> is optional. It can be a public, unique identifier for a protocol or
application. Its purpose is to ensure that distinct keys will be created even
if the input keying material is accidentally reused across protocols.

C<$flags> is optional. It is the flags used for the C<$prk>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a master key of the requested size.

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

=head2 hkdf_E<lt>primitiveE<gt>_extract_init

  my $multipart = hkdf_sha256_extract_init($salt, $flags);

C<$salt> is optional. It can be a public, unique identifier for a protocol or
application. Its purpose is to ensure that distinct keys will be created even
if the input keying material is accidentally reused across protocols.

C<$flags> is optional. It is the flags used for the multipart protected memory
object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a multipart hkdf object. See
L</MULTI-PART INTERFACE>.

Also see the notes for L</hkdf_E<lt>primitiveE<gt>_extract>.

=head2 hkdf_E<lt>primitiveE<gt>_keygen

  my $prk = hkdf_sha256_keygen($flags);

C<$flags> is optional. It is the flags used for the C<$prk>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a PRK (master key) of
L</hkdf_E<lt>primitiveE<gt>_KEYBYTES> bytes.

=head1 MULTI-PART INTERFACE

To extract a pseudorandom key from an arbitrary size of input keying material,
you may wish to use the multi-part interface. A multipart hkdf object is
created by calling the L</hkdf_E<lt>primitiveE<gt>_extract_init> function with
optional salt. Key material can be added by calling the </update> method of
that object as many times as desired. An output PRK (master key) is generated
by calling its L</final> method. Do not continue to use the object after
calling L</final>.

The precalculated hkdf object is an opaque protected memory object which
provides the following methods:

=head2 final

  my $prk = $multipart->final($flags);

C<$flags> is optional. It is the flags used for the C<$prk>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a PRK (master key) of
L</hkdf_E<lt>primitiveE<gt>_KEYBYTES> bytes.

Once C<final> has been called, the multipart object must not be used further.

=head2 update

  $multipart->update(@key_data);

Adds all given arguments (stringified) to input keying material. Any argument
may be a L<Crypt::Sodium::XS::MemVault>.

=head1 CONSTANTS

=head2 hkdf_E<lt>primitiveE<gt>_BYTES_MAX

Returns the maximum size, in bytes, of output from
L</hkdf_E<lt>primitiveE<gt>_expand>.

=head2 hkdf_E<lt>primitiveE<gt>_BYTES_MIN

Defined by libsodium to be 0.

=head2 hkdf_E<lt>primitiveE<gt>_KEYBYTES

Returns the size, in bytes, of a secret key (both PRK and subkey).

=head1 ALGORITHMS

All constants and functions have
C<hkdf_E<lt>algorithmE<gt>>-prefixed couterparts (e.g., hkdf_sha256_expand,
hkdf_sha512_BYTES_MAX).

=over 4

=item * sha256

=item * sha512

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::hkdf>

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
