package Crypt::Sodium::XS::stream;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(
    KEYBYTES
    MESSAGEBYTES_MAX
    NONCEBYTES
  );

  my @bases = qw(
    keygen
    nonce
    xor
  );

  my $default = [
    "stream",
    "stream_xor_ic",
    (map { "stream_$_" } @bases),
    (map { "stream_$_" } @constant_bases, "PRIMITIVE"),
  ];

  my $chacha20 = [
    "stream_chacha20",
    "stream_chacha20_xor_ic",
    (map { "stream_chacha20_$_" } @bases),
    (map { "stream_chacha20_$_" } @constant_bases),
  ];

  my $chacha20_ietf = [
    "stream_chacha20_ietf",
    "stream_chacha20_ietf_xor_ic",
    (map { "stream_chacha20_ietf_$_" } @bases),
    (map { "stream_chacha20_ietf_$_" } @constant_bases),
  ];

  my $salsa20 = [
    "stream_salsa20",
    "stream_salsa20_xor_ic",
    (map { "stream_salsa20_$_" } @bases),
    (map { "stream_salsa20_$_" } @constant_bases),
  ];

  my $salsa2012 = [
    "stream_salsa2012",
    (map { "stream_salsa2012_$_" } @bases),
    (map { "stream_salsa2012_$_" } @constant_bases),
  ];

  my $xchacha20 = [
    "stream_xchacha20",
    "stream_xchacha20_xor_ic",
    (map { "stream_xchacha20_$_" } @bases),
    (map { "stream_xchacha20_$_" } @constant_bases),
  ];

  my $xsalsa20 = [
    "stream_xsalsa20",
    "stream_xsalsa20_xor_ic",
    (map { "stream_xsalsa20_$_" } @bases),
    (map { "stream_xsalsa20_$_" } @constant_bases),
  ];

  our %EXPORT_TAGS = (
    all => [ @$default, @$chacha20, @$chacha20_ietf, @$salsa20,
             @$salsa2012, @$xchacha20, @$xsalsa20 ],
    default => $default,
    chacha20 => $chacha20,
    chacha20_ietf => $chacha20_ietf,
    salsa20 => $salsa20,
    salsa2012 => $salsa2012,
    xchacha20 => $xchacha20,
    xsalsa20 => $xsalsa20,
  );

  our @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

package Crypt::Sodium::XS::OO::stream;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_NONCEBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::stream::stream_PRIMITIVE,
    keygen => \&Crypt::Sodium::XS::stream::stream_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream,
    xor => \&Crypt::Sodium::XS::stream::stream_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_xor_ic,
  },
  chacha20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_chacha20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_NONCEBYTES,
    PRIMITIVE => sub { 'chacha20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_chacha20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_chacha20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_chacha20,
    xor => \&Crypt::Sodium::XS::stream::stream_chacha20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_chacha20_xor_ic,
  },
  chacha20_ietf => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_NONCEBYTES,
    PRIMITIVE => sub { 'chacha20_ietf' },
    keygen => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf,
    xor => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_chacha20_ietf_xor_ic,
  },
  salsa20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_salsa20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_salsa20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_salsa20_NONCEBYTES,
    PRIMITIVE => sub { 'salsa20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_salsa20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_salsa20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_salsa20,
    xor => \&Crypt::Sodium::XS::stream::stream_salsa20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_salsa20_xor_ic,
  },
  salsa2012 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_salsa2012_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_salsa2012_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_salsa2012_NONCEBYTES,
    PRIMITIVE => sub { 'salsa2012' },
    keygen => \&Crypt::Sodium::XS::stream::stream_salsa2012_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_salsa2012_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_salsa2012,
    xor => \&Crypt::Sodium::XS::stream::stream_salsa2012_xor,
    xor_ic => sub { die "xor_ic not supported for salsa2012 primitive" },
  },
  xchacha20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_xchacha20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_xchacha20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_xchacha20_NONCEBYTES,
    PRIMITIVE => sub { 'xchacha20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_xchacha20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_xchacha20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_xchacha20,
    xor => \&Crypt::Sodium::XS::stream::stream_xchacha20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_xchacha20_xor_ic,
  },
  xsalsa20 => {
    KEYBYTES => \&Crypt::Sodium::XS::stream::stream_xsalsa20_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::stream::stream_xsalsa20_MESSAGEBYTES_MAX,
    NONCEBYTES => \&Crypt::Sodium::XS::stream::stream_xsalsa20_NONCEBYTES,
    PRIMITIVE => sub { 'xsalsa20' },
    keygen => \&Crypt::Sodium::XS::stream::stream_xsalsa20_keygen,
    nonce => \&Crypt::Sodium::XS::stream::stream_xsalsa20_nonce,
    stream => \&Crypt::Sodium::XS::stream::stream_xsalsa20,
    xor => \&Crypt::Sodium::XS::stream::stream_xsalsa20_xor,
    xor_ic => \&Crypt::Sodium::XS::stream::stream_xsalsa20_xor_ic,
  },
);

sub Crypt::Sodium::XS::stream::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::stream::primitives;

sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub MESSAGEBYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{MESSAGEBYTES_MAX}; }
sub NONCEBYTES { my $self = shift; goto $methods{$self->{primitive}}->{NONCEBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub nonce { my $self = shift; goto $methods{$self->{primitive}}->{nonce}; }
sub stream { my $self = shift; goto $methods{$self->{primitive}}->{stream}; }
sub xor { my $self = shift; goto $methods{$self->{primitive}}->{xor}; }
sub xor_ic { my $self = shift; goto $methods{$self->{primitive}}->{xor_ic}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::stream - Stream ciphers

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  my $xs_stream = Crypt::Sodium::XS->stream;
  
  # TODO (still)

=head1 DESCRIPTION

These functions are stream ciphers. They do not provide authenticated
encryption. They can be used to generate pseudo-random data from a key, or as
building blocks for implementing custom constructions, but they are not
alternatives to L<Crypt::Sodium::XS::secretbox>.

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>stream> method.

  my $stream = Crypt::Sodium::XS->stream;
  my $stream = Crypt::Sodium::XS->stream(primitive => 'xchacha20');

Returns a new stream object.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::stream>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $stream->primitive;
  $stream->primitive('xchacha20');

Gets or sets the primitive used for all operations by this object. It must be
one of the primitives listed in L</PRIMITIVES>, including C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = $stream->primitives;
  my @primitives = Crypt::Sodium::XS::stream->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $stream->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 keygen

  my $key = $stream->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of L</KEYBYTES> bytes.

=head2 nonce

  my $nonce = $stream->nonce($base);

C<$base> is optional. It must be less than or equal to L</NONCEBYTES> bytes. If
not provided, the nonce will be random.

Returns a nonce of L</NONCEBYTES> bytes.

=head2 stream

  my $stream_data = $stream->stream($out_size, $nonce, $key);

C<$out_size> is the desired size, in bytes, of stream data output.

C<$nonce> is the nonce used to encrypt the stream data. It must be
L</NONCEBYTES> bytes.

C<$key> is the secret key used to encrypt the stream data. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns C<$out_size> bytes of stream data.

=head2 xor

  my $outdata = $stream->xor($indata, $nonce, $key, $flags);

C<$indata> is the data to xor. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to xor the data. It must be L</NONCEBYTES> bytes.

C<$key> is the secret key used to xor the data. It must be L</KEYBYTES> bytes.
It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. If provided, the returned data will be a
L<Crypt::Sodium::XS::MemVault>, created with the given flags.

Returns the xor result. May be a L<Crypt::Sodium::XS::MemVault>; see C<$flags>
above.

When using this method to decrypt data, C<$flags> should be passed (even if 0
or undef) to ensure the decrypted data is protected with a
L<Crypt::Sodium::XS::MemVault>.

=head2 xor_ic

  my $outdata
    = $stream->xor_ic($indata, $nonce, $internal_counter, $key, $flags);

B<Note>: xor_ic is not supported with the C<salsa2012> primitive.

C<$indata> is the data to xor. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to xor the data. It must be L</NONCEBYTES> bytes.

C<$internal_counter> is the initial value of the block counter.

C<$key> is the secret key used to xor the data. It must be L</KEYBYTES> bytes.
It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. If provided, the returned data will be a
L<Crypt::Sodium::XS::MemVault>, created with the given flags.

Returns the xor result. May be a L<Crypt::Sodium::XS::MemVault>; see C<$flags>
above.

L</xor_ic> is similar to L</xor> but adds the ability to set the initial value
of the block counter (C<$internal_counter>) to a non-zero value. This permits
direct access to any block without having to compute the previous ones.

When using this method to decrypt data, C<$flags> should be passed (even if 0
or undef) to ensure the decrypted data is protected with a
L<Crypt::Sodium::XS::MemVault>.

=head2 KEYBYTES

  my $key_size = $stream->KEYBYTES;

Returns the size, in bytes, of a secret key.

=head2 MESSAGEBYTES_MAX

  my $plaintext_max_size = $stream->MESSAGEBYTES_MAX;

Returns the size, in bytes, of the maximum size of any message to be encrypted.

=head2 NONCEBYTES

  my $nonce_size = $stream->NONCEBYTES;

Returns the size, in bytes, of a nonce.

=head1 PRIMITIVES

Except for salsa2012, which does not provide an xor_ic function, all constants
(except _PRIMITIVE) and functions have C<stream_E<lt>primitiveE<gt>>-prefixed
counterparts (e.g., stream_chacha20_ietf_xor_ic, stream_salsa2012_KEYBYTES).

=over 4

=item * chacha20

=item * chacha20_ietf

ChaCha20 is a stream cipher developed by Daniel J. Bernstein. Its original
design expands a 256-bit key into 2^64 randomly accessible streams, each
containing 2^64 randomly accessible 64-byte (512 bits) blocks. It is a variant
of Salsa20 with better diffusion.

ChaCha20 doesn’t require any lookup tables and avoids the possibility of timing
attacks.

Internally, ChaCha20 works like a block cipher used in counter mode. It
includes an internal block counter to avoid incrementing the nonce after each
block.

Two variants of the ChaCha20 cipher are implemented in libsodium:

* The original ChaCha20 cipher with a 64-bit nonce and a 64-bit counter,
  allowing a practically unlimited amount of data to be encrypted with the same
  (key, nonce) pair.

* The IETF variant increases the nonce size to 96 bits, but reduces the counter
  size down to 32 bits, allowing only up to 256 GB of data to be safely
  encrypted with a given (key, nonce) pair.

These primitives should only be used to implement protocols that specifically
require them. For all other applications, it is recommended to use the XSalsa20
or the ChaCha20-based construction with an extended nonce, XChaCha20.

=item * salsa20

=item * salsa2012

Salsa20 is a stream cipher developed by Daniel J. Bernstein that expands a
256-bit key into 2^64 randomly accessible streams, each containing 2^64
randomly accessible 64-byte (512 bits) blocks.

Salsa20 doesn’t require any lookup tables and avoids the possibility of timing
attacks.

Internally, Salsa20 works like a block cipher used in counter mode. It uses a
dedicated 64-bit block counter to avoid incrementing the nonce after each
block.

The extended-nonce construction XSalsa20 is generally recommended over raw
Salsa20, as it makes it easier to safely generate nonces.

The nonce is 64 bits long. In order to prevent nonce reuse, if a key is being
reused, it is recommended to increment the previous nonce instead of generating
a random nonce every time a new stream is required.

Salsa2012 is a faster, reduced-rounds (reduced from 20 to 12) primitive.

=item * xchacha20

XChaCha20 is a variant of ChaCha20 with an extended nonce, allowing random
nonces to be safe.

XChaCha20 doesn’t require any lookup tables and avoids the possibility of
timing attacks.

Internally, XChaCha20 works like a block cipher used in counter mode. It uses
the HChaCha20 hash function to derive a subkey and a subnonce from the original
key and extended nonce, and a dedicated 64-bit block counter to avoid
incrementing the nonce after each block.

XChaCha20 is generally recommended over plain ChaCha20 due to its extended
nonce size, and its comparable performance. However, XChaCha20 is currently not
widely implemented outside the libsodium library, due to the absence of formal
specification.

=item * xsalsa20 (default)

XSalsa20 is a stream cipher based upon Salsa20 but with a much longer nonce:
192 bits instead of 64 bits.

XSalsa20 uses a 256-bit key as well as the first 128 bits of the nonce in order
to compute a subkey. This subkey, as well as the remaining 64 bits of the
nonce, are the parameters of the Salsa20 function used to actually generate the
stream.

Like Salsa20, XSalsa20 is immune to timing attacks and provides its own 64-bit
block counter to avoid incrementing the nonce after each block.

But with XSalsa20’s longer nonce, it is safe to generate nonces using
randombytes_buf() for every message encrypted with the same key without having
to worry about a collision.

=back

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead or in addition.

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<stream_E<lt>primitiveE<gt>_*> functions and constants for that primitive.
A C<:all> tag imports everything.

=head2 stream_keygen

=head2 stream_E<lt>primitiveE<gt>_keygen

  my $key = stream_keygen($flags);

Same as L</keygen>.

=head2 stream_nonce

=head2 stream_E<lt>primitiveE<gt>_nonce

  my $nonce = stream_nonce($base);

Same as L</nonce>.

=head2 stream

=head2 stream (function)

  my $stream_data = stream($size, $nonce, $key);

Same as L</stream> (method).

=head2 stream_xor

=head2 stream_E<lt>primitiveE<gt>_xor

  my $ciphertext = stream_xor($plaintext, $nonce, $key, $flags);

Same as L</xor>.

=head2 stream_xor_ic

=head2 stream_E<lt>primitiveE<gt>_xor_ic

  my $ciphertext
    = stream_xor_ic($plaintext, $nonce, $internal_counter, $key, $flags);

Same as L</xor_ic>.

=head1 CONSTANTS

=head2 stream_KEYBYTES

=head2 stream_E<lt>primitiveE<gt>_KEYBYTES

  my $key_size = stream_KEYBYTES();

Same as L</KEYBYTES>.

=head2 stream_MESSAGEBYTES_MAX

=head2 stream_E<lt>primitiveE<gt>_MESSAGEBYTES_MAX

  my $plaintext_max_size = stream_MESSAGEBYTES_MAX();

Same as L</MESSAGEBYTES_MAX>.

=head2 stream_NONCEBYTES

=head2 stream_E<lt>primitiveE<gt>_NONCEBYTES

  my $nonce_size = stream_NONCEBYTES();

Same as L</NONCEBYTES>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://doc.libsodium.org/advanced/stream_ciphers>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/chacha20>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/xchacha20>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/salsa20>

=item L<https://doc.libsodium.org/advanced/stream_ciphers/xsalsa20>

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
