package Crypt::Sodium::XS::stream;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

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

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::stream - Stream ciphers

=head1 SYNOPSIS

  use Crypt::Sodium::XS::stream ":default";

=head1 DESCRIPTION

These functions are stream ciphers. They do not provide authenticated
encryption. They can be used to generate pseudo-random data from a key, or as
building blocks for implementing custom constructions, but they are not
alternatives to L<Crypt::Sodium::XS::secretbox>.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants as documented below. A separate import tag is provided for each of
the primitives listed in L</PRIMITIVES>. For example, C<:chacha20> imports
C<stream_chacha20_xor>. You should use at least one import tag.

=head2 stream_keygen

  my $key = stream_keygen();

=head2 stream_nonce

  my $nonce = stream_nonce();

=head2 stream

  my $stream_data = stream($length, $nonce, $key);

=head2 stream_xor

  my $ciphertext = stream_xor($plaintext, $nonce, $key);

=head2 stream_xor_ic

  my $ciphertext = stream_xor_ic($plaintext, $nonce, $internal_counter, $key);

=head1 CONSTANTS

=head2 stream_KEYBYTES

  my $key_length = stream_KEYBYTES();

=head2 stream_MESSAGEBYTES_MAX

  my $plaintext_max_length = stream_MESSAGEBYTES_MAX();

=head2 stream_NONCEBYTES

  my $nonce_length = stream_NONCEBYTES();

=head1 PRIMITIVES

Except for salsa2012, which does not provide an xor_ic function, all constants
(except _PRIMITIVE) and functions have C<stream_E<lt>primitiveE<gt>>-prefixed
counterparts (e.g., stream_chacha20_ietf_xor_ic, stream_salsa2012_KEYBYTES).

=over 4

=item * chacha20

=item * chacha20_ietf

=item * salsa20

=item * salsa2012

=item * xchacha20

=item * xsalsa20

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::stream>

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
