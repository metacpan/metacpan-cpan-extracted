package Crypt::Sodium::XS::ipcrypt;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(BYTES INPUTBYTES KEYBYTES OUTPUTBYTES TWEAKBYTES);

  my $default = [
    (map { "ipcrypt_$_" } qw(BYTES KEYBYTES decrypt encrypt keygen)),
  ];

  my @ndtype_constants = qw(INPUTBYTES KEYBYTES OUTPUTBYTES TWEAKBYTES);
  my $nd = [
    (map { "ipcrypt_ND_$_" } @ndtype_constants),
    (map { "ipcrypt_nd_$_" } qw(decrypt encrypt keygen)),
  ];
  my $ndx = [
    (map { "ipcrypt_NDX_$_" } @ndtype_constants),
    (map { "ipcrypt_ndx_$_" } qw(decrypt encrypt keygen)),
  ];

  my $pfx = [
    (map { "ipcrypt_PFX_$_" } qw(BYTES KEYBYTES)),
    (map { "ipcrypt_pfx_$_" } qw(decrypt encrypt keygen)),
  ];

  my $features = ['ipcrypt_available'];

  our %EXPORT_TAGS = (
    all => [ @$features, @$default, @$nd, @$ndx, @$pfx ],
    features => $features,
    default => $default,
    nd => $nd,
    ndx => $ndx,
    pfx => $pfx,
  );

  our @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

package Crypt::Sodium::XS::OO::ipcrypt;
use parent 'Crypt::Sodium::XS::OO::Base';

# NB: some constants added for consistency which are not provided by libsodium.
# for deterministic and pfx INPUTBYTES and OUTPUTBYTES are defined to be the
# same as BYTES. TWEAKBYTES is also defined as a constant of 0.
sub zero { 0 }
my %methods = (
  default => {
    INPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_BYTES,
    BYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_KEYBYTES,
    OUTPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_BYTES,
    TWEAKBYTES => \&zero,
    decrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_decrypt,
    encrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_encrypt,
    keygen => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_keygen,
  },
  nd => {
    BYTES => sub { die "BYTES not implemented for ND" },
    INPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_ND_INPUTBYTES,
    KEYBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_ND_KEYBYTES,
    OUTPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_ND_OUTPUTBYTES,
    TWEAKBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_ND_TWEAKBYTES,
    decrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_nd_decrypt,
    encrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_nd_encrypt,
    keygen => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_nd_keygen,
  },
  ndx => {
    BYTES => sub { die "BYTES not implemented for NDX" },
    INPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_NDX_INPUTBYTES,
    KEYBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_NDX_KEYBYTES,
    OUTPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_NDX_OUTPUTBYTES,
    TWEAKBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_NDX_TWEAKBYTES,
    decrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_ndx_decrypt,
    encrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_ndx_encrypt,
    keygen => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_ndx_keygen,
  },
  pfx => {
    BYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_PFX_BYTES,
    INPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_PFX_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_PFX_KEYBYTES,
    OUTPUTBYTES => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_PFX_BYTES,
    TWEAKBYTES => \&zero,
    decrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_pfx_decrypt,
    encrypt => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_pfx_encrypt,
    keygen => \&Crypt::Sodium::XS::ipcrypt::ipcrypt_pfx_keygen,
  },
);

sub Crypt::Sodium::XS::ipcrypt::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::ipcrypt::primitives;

sub available { goto \&Crypt::Sodium::XS::ipcrypt::ipcrypt_available }

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES} }
sub INPUTBYTES { my $self = shift; goto $methods{$self->{primitive}}->{INPUTBYTES} }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES} }
sub OUTPUTBYTES { my $self = shift; goto $methods{$self->{primitive}}->{OUTPUTBYTES} }
sub TWEAKBYTES { my $self = shift; goto $methods{$self->{primitive}}->{TWEAKBYTES} }
sub decrypt { my $self = shift; goto $methods{$self->{primitive}}->{decrypt}; }
sub encrypt { my $self = shift; goto $methods{$self->{primitive}}->{encrypt}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::ipcrypt - IP address encryption

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  use Crypt::Sodium::XS::Util qw(sodium_bin2ip sodium_ip2bin);

  my $ipcrypt = Crypt::Sodium::XS->ipcrypt;

  die "no libsodium ipcrypt support" unless $ipcrypt->available;

  my $ip = "172.18.37.43"; # ipv4 or ipv6 address

  my $key = $ipcrypt->keygen;

  my $encrypted = $ipcrypt->encrypt(sodium_ip2bin($ip), $key);

  $ip eq sodium_bin2ip($ipcrypt->decrypt($encrypted, $key)); # true

=head1 DESCRIPTION

The ipcrypt API provides efficient, secure encryption of IP addresses (IPv4 and
IPv6) for privacy-preserving storage, logging, and analytics.

Unlike truncation (which irreversibly destroys data) or hashing (which prevents
decryption), ipcrypt provides reversible encryption with well-defined security
properties while maintaining operational utility.

=head2 Use cases

=over 4

=item Privacy-preserving logs

Encrypt IP addresses in web server access logs, DNS query logs, or application
logs while retaining the ability to decrypt when needed.

=item Rate limiting and abuse detection

Count requests per client, detect brute-force attempts, or implement request
throttling using deterministic encryption.

=item Analytics without exposure

Count unique visitors, analyze geographic traffic patterns, or build user
behavior analytics without revealing actual addresses.

=item Data sharing

Share network data with security researchers, cloud providers, or partner
organizations without exposing actual client addresses.

=item Database storage

Store encrypted IP addresses in databases with indexes on the encrypted values
(deterministic mode). Query, group, and sort by client without exposing actual
addresses.

=back

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>ipcrypt> method.

  my $ipcrypt = Crypt::Sodium::XS->ipcrypt;
  my $ipcrypt = Crypt::Sodium::XS->ipcrypt(primitive => 'ndx');

Returns a new ipcrypt object.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::ipcrypt>.

=head1 ATTRIBUTES

=head2 primitive

  my $variant = $ipcrypt->primitive;
  $ipcrypt->primitive('pfx');

Gets or sets the variant used for all operations by this object. Must be one of
the variant names listed in L</VARIANTS>, including C<default>.

The attribute name C<primitive> is used for consistency with all other modules,
even though for ipcrypt these are called variants.

=head1 METHODS

=head2 available

  my $has_ipcrypt = $ipcrypt->available;

Returns true if L<Crypt::Sodium::XS> supports ipcrypt, false otherwise. ipcrypt
will only be supported if L<Crypt::Sodium::XS> was built with a new enough (>=
1.0.21) version of libsodium.

=head2 primitives

  my @variants = $ipcrypt->primitives;
  my @variants = Crypt::Sodium::XS::ipcrypt->primitives;

Returns a list of all supported variant names, including C<default>.

Can be called as a class method.

=head2 decrypt

  my $binip = $ipcrypt->decrypt($encrypted, $key);

C<$encrypted> is the encrypted IP data to decrypt.

C<$key> is the secret key used to encrypt the data. It must be L</KEYBYTES>
bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the decrypted IP address as a 16-byte packed value. See
L<Crypt::Sodium::XS::Util/sodium_bin2ip> for details of this packed value,
including how to generate an IP string from it (example above in L</SYNOPSIS>).

=head2 encrypt

  my $encrypted = $ipcrypt->encrypt($binip, $key, $tweak);

C<$binip> is an IP address packed as a 16-byte value. See
L<Crypt::Sodium::XS::Util/sodium_ip2bin> for details of this packed value,
including how to generate it from an IP string (example above in L</SYNOPSIS>).

C<$key> is the secret key used to encrypt the IP. It must be L</KEYBYTES>
bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$tweak> is optional. It is used in non-deterministic (nd and ndx) variants to
ensure the same address encrypts to different outputs. It should be randomly
generated and must be L</TWEAKBYTES> bytes in size. If not given, it will be
generated randomly. For deterministic and prefix-preserving variants, it is
ignored. It is unlikely you would ever want to provide this argument
explicitly.

Returns the encrypted output, which is L</OUTPUTBYTES> in size.

Note that there is no need to keep the tweak value. It is included in the
output.

=head2 keygen

  my $key = $ipcrypt->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of
L</ipcrypt_KEYBYTES> bytes.

=head2 BYTES

  my $plaintext_and_encrypted_size = $ipcrypt->BYTES;

(deterministic and prefix-preserving variants only) Returns the size, in bytes,
of both encryption input and output. Defined to be 16.

=head2 INPUTBYTES

  my $plaintext_size = $ipcrypt->INPUTBYTES;

Returns the size, in bytes, of encryption input. Defined to be 16.

=head2 KEYBYTES

  my $key_size = $ipcrypt->KEYBYTES;

Returns the size, in bytes, of a secret key.

=head2 OUTPUTBYTES

  my $output_size = $ipcrypt->OUTPUTBYTES;

Returns the size, in bytes, of encryption output.

=head2 TWEAKBYTES

  my $tweak_size = $ipcrypt->TWEAKBYTES;

Returns the size, in bytes, of a tweak value. For deterministic and
prefix-preserving variants, this is always 0 as they do not use a tweak value.

=head1 VARIANTS

ipcrypt provides four variants with different security and format trade-offs.
The variant is chosen by the L</primitive> attribute. It can be set to one of
these four variants by the name listed in parentheses:

=over 4

=item default (Deterministic)

* 16 byte key

* 16 byte output

* Same input always produces same output; format-preserving

* Algorithm: Single-block AES-128

=item nd (Non-Deterministic)

* 16 byte key

* 24 byte output

* Different output each time; 8-byte random tweak

* Algorithm: KIASU-BC (tweakable AES-128 with 64-bit tweak)

=item ndx (Extended Non-Deterministic)

* 32 byte key

* 32 byte output

* Different output each time; 16-byte random tweak

* Algorithm: AES-XTS (IEEE 1619-2007) with 128-bit tweak

=item pfx (Prefix-Preserving)

* 32 byte key

* 16 byte output

* Preserves network prefix relationships

* Algorithm: Bit-by-bit format-preserving encryption using XOR of two AES-128
permutations

=back

=head2 Choosing the right variant

Use deterministic mode for rate limiting, deduplication, unique visitor
counting, database indexing, or anywhere you need to identify the same address
across multiple observations. Fastest option. Trade-off: identical inputs
produce identical outputs.

Use ND mode when sharing data externally or when preventing correlation across
observations matters. Each encryption produces a different ciphertext, so an
observer cannot tell if two records came from the same address. Good for log
archival, third-party analytics, or data exports.

Use NDX mode for maximum security when you need the non-deterministic property
and will perform very large numbers of encryptions (billions) with the same
key. The larger tweak space provides a higher birthday bound.

Use PFX mode for network analysis applications: DDoS research, traffic studies,
packet trace anonymization, or any scenario where understanding which addresses
belong to the same network matters more than hiding that relationship.

All implementations use hardware acceleration when available (AES-NI on x86-64,
ARM Crypto extensions on ARM).

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead (or in addition, though
that's unlikely to be necessary).

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A C<:features> tag imports the C<ipcrypt_available>
feature test function. A separate C<:E<lt>variantE<gt>> import tag is provided
for each of the variants listed in L</VARIANTS>. These tags import the
C<iprypt_E<lt>variantE<gt>_*> functions and constants for that variant.

=head2 ipcrypt_available

  my $has_ipcrypt = ipcrypt_available();

Same as L</available>.

=head2 ipcrypt_decrypt

=head2 ipcrypt_<variant>_decrypt

  my $binip = ipcrypt_decrypt($encrypted, $key);

Same as L</decrypt>.

=head2 ipcrypt_encrypt

=head2 ipcrypt_<variant>_encrypt

  my $encrypted = ipcrypt_encrypt($binip, $key, $tweak);

Same as L</encrypt>.

=head2 ipcrypt_keygen

=head2 ipcrypt_<variant>_keygen

  my $key = ipcrypt_keygen($flags);

Same as L</keygen>.

=head1 CONSTANTS

=head2 ipcrypt_BYTES

=head2 ipcrypt_pfx_BYTES

  my $plaintext_and_encrypted_size = ipcrypt_BYTES();

Same as L</BYTES>.

=head2 ipcrypt_INPUTBYTES

=head2 ipcrypt_<variant>_INPUTBYTES

  my $plaintext_size = ipcrypt_INPUTBYTES();

Same as L</INPUTBYTES>.

=head2 ipcrypt_KEYBYTES

=head2 ipcrypt_<variant>_KEYBYTES

  my $key_size = ipcrypt_KEYBYTES();

Same as L</KEYBYTES>.

=head2 ipcrypt_OUTPUTBYTES

=head2 ipcrypt_<variant>_OUTPUTBYTES

  my $output_size = ipcrypt_OUTPUTBYTES();

Same as L</OUTPUTBYTES>.

=head2 ipcrypt_TWEAKBYTES

=head2 ipcrypt_<variant>_TWEAKBYTES

  my $tweak_size = ipcrypt_TWEAKBYTES();

Same as L</TWEAKBYTES>.

=head1 Security considerations

=over 4

=item What ipcrypt protects against

* Unauthorized parties learning original addresses without the key

* Statistical analysis revealing traffic patterns (non-deterministic modes)

* Brute-force attacks on the address space (128-bit AES security)

=item What ipcrypt does not protect against

* Active attackers modifying, reordering, or removing encrypted addresses

* Correlation of identical addresses (deterministic mode)

* Traffic analysis based on volume and timing metadata

=item Key management

* Generate keys using L</ipcrypt_keygen>.

* Never reuse keys across different variants; use L<Crypt::Sodium::XS::hkdf> to
derive separate keys if needed

* Rotate keys based on usage volume and security requirements

=item Tweak generation (ND/NDX modes)

* Tweaks can be randomly generated using L<Crypt::Sodium::XS::Util/sodium_random_bytes>.

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://doc.libsodium.org/doc/secret-key_cryptography/ip_address_encryption>

=item L<https://ipcrypt-std.github.io/>

=item L<https://datatracker.ietf.org/doc/draft-denis-ipcrypt/>

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
