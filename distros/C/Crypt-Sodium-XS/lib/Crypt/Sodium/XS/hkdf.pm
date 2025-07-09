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
my $hkdf = [ @$hkdf_sha256, @$hkdf_sha512 ];
push(@$_, 'hkdf_available') for $hkdf, $hkdf_sha256, $hkdf_sha512;

our %EXPORT_TAGS = (
  all => [ @$hkdf ],
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
  $multipart->update("initial");
  $multipart->update(" key material", " added in parts");
  $prk = $multipart->final;
  ...

=head1 DESCRIPTION

NOTE: Secret keys used to encrypt or sign confidential data have to be chosen
from a very large keyspace. However, passwords are usually short,
human-generated strings, making dictionary attacks practical. If you are
intending to derive keys from a password, see L<Crypt::Sodium::XS::pwhash>
instead.

HKDF (HMAC-based Extract-and-Expand Key Derivation Function) is a key
derivation function used by many standard protocols.  It actually includes two
operations:

=over 4

=item extract

this operation absorbs an arbitrary-long sequence of bytes and outputs a
fixed-size master key (also known as PRK), suitable for use with the second
function (expand).

=item expand

this operation generates an variable size subkey given a master key (also known
as PRK) and a description of a key (or “context”) to derive from it. That
operation can be repeated with different descriptions in order to derive as
many keys as necessary. The latter can be used without the former, if a
randomly sampled key of the right size is already available.

=back

Note that in libsodium, HKDF functions are prefixed C<kdf_hkdf_>. In this
library, they are prefixed with only C<hkdf_>.

=head1 FUNCTIONS

Nothing is exported by default. L<Crypt::Sodium::XS::hkdf>, like libsodium,
supports only the algorithm-specific functions for HKDF. A separate import tag
is provided for each of the algorithms listed in L</ALGORITHMS>. For example,
the C<:sha256> tag imports C<hkdf_sha256_expand> and the C<:sha512> tag imports
C<hkdf_sha512_expand>. All tags will import feature test functions (e.g.,
C<hkdf_available>). An C<:all> tag imports all functions and constants.  You
should use at least one import tag.

=head2 hkdf_available

A constant sub indicating the availability of HKDF in the linked version of
libsodium. It is a good idea to test for availability, as at time of writing it
is only available in the most recent library version and may not yet be widely
deployed.

=head2 hkdf_sha256_expand

  my $subkey = hkdf_sha256_expand($prk, $out_len);
  my $subkey = hkdf_sha256_expand($prk, $out_len, $context);

This function derives a subkey of length C<$out_len> from a context/description
C<$context> and a master key C<$prk>.

Up to L</hkdf_sha256_BYTES_MAX> bytes can be produced.

The generated keys satifsy the typical requirements of keys used for symmetric
cryptography. In particular, they appear to be sampled from a uniform
distribution over the entire range of possible keys. Contexts don’t have to
secret. They just need to be distinct in order to produce distinct keys from
the same master key.

Any L</hkdf_sha256_KEYBYTES> bytes key that appears to be sampled from a
uniform distribution can be used for the prk. For example, the output of a key
exchange mechanism (such as from L<Crypt::Sodium::XS::kx>) can be used as a
master key. For convenience, the L</hkdf_sha256_keygen> function creates a
random prk. The master key should remain secret.

This function is effectively a standard alternative to
L<Crypt::Sodium::XS::kdf::derive_from_key>. It is slower, but the context can
be of any size.

=head2 hkdf_sha256_extract

  my $prk = hkdf_sha256_extract($ikm);
  my $prk = hkdf_sha256_extract($ikm, $salt);

The C<hkdf_sha256_extract> function creates a master key (prk) given Input
Keying Material (IKM) <$ikm> and C<$salt>. The master key can be generated with
L</hkdf_sha256_keygen>.

C<$salt> is optional. It can be a public, unique identifier for a protocol or
application. Its purpose is to ensure that distinct keys will be created even
if the input keying material is accidentally reused across protocols.

A UUID is a decent example of a salt. There is no minimum length.

If input keying material cannot be accidentally reused, using an empty (undef
or empty string) salt is perfectly acceptable. IKM is an arbitrary-long byte
sequence. The bytes don’t have to be sampled from a uniform distribution. It
can be any combination of text and binary data.

But the overall sequence needs to include some entropy.

The resulting PRK will roughly have the same entropy. The “extract” operation
effectively extracts the entropy and packs it into a fixed-size key, but it
doesn’t add any entropy.

=head2 hkdf_sha256_keygen

  my $prk = hkdf_keygen();

Generate a random secret key suitable for use as a master key with with
L</hkdf_sha256_expand>.

=head1 MULTI-PART INTERFACE

To extract a pseudorandom key from an arbitrary length of initial key material,
you may wish to use the multi-part interface. A multipart hkdf object is
created by calling the L</hkdf_sha256_extract_init> function with optional salt.
Key material can be added by calling the </update> method of that object as
many times as desired. An output master key (prk) is generated by calling its
L</final> method. Do not continue to use the object after calling L</final>.

The precalculated hkdf object is an opaque object which provides the following
methods:

=head2 final

  my $prk = $multipart->final;

=head2 update

  $multipart->update($key_data);
  $multipart->update(@key_data);

=head1 CONSTANTS

=head2 hkdf_sha256_BYTES_MAX

Maximum length of output from C<expand> functions.

=head2 hkdf_sha256_BYTES_MIN

Defined by libsodium to be 0.

=head2 hkdf_sha256_KEYBYTES

Length in bytes of C<keygen> function output, and length in bytes of any PRK.

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
