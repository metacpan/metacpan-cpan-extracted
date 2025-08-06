package Crypt::Sodium::XS::secretbox;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  NONCEBYTES
  KEYBYTES
  MACBYTES
);

my @bases = qw(
  decrypt
  decrypt_detached
  encrypt
  encrypt_detached
  keygen
  nonce
);

my $default = [
  (map { "secretbox_$_" } @bases),
  (map { "secretbox_$_" } @constant_bases, "PRIMITIVE"),
];
my $xchacha20poly1305 = [
  (map { "secretbox_xchacha20poly1305_$_" } @bases),
  (map { "secretbox_xchacha20poly1305_$_" } @constant_bases),
];
my $xsalsa20poly1305 = [
  (map { "secretbox_xsalsa20poly1305_$_" } @bases),
  (map { "secretbox_xsalsa20poly1305_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all => [ @$default, @$xchacha20poly1305, @$xsalsa20poly1305 ],
  default => $default,
  xchacha20poly1305 => $xchacha20poly1305,
  xsalsa20poly1305 => $xsalsa20poly1305,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::secretbox - Secret key authenticated encryption

=head1 SYNOPSIS

  use Crypt::Sodium::XS::secretbox ":default";
  use Crypt::Sodium::XS::Util "sodium_increment";

  my $sk = secretbox_keygen();
  my $nonce = secretbox_nonce();

  my $ct = secretbox_encrypt("hello", $nonce, $sk);
  my $pt = secretbox_decrypt($ct, $nonce, $sk);
  # $pt is now "hello" (MemVault)

  $nonce = sodium_increment($nonce);
  ($ct, my $tag) = secretbox_encrypt_detached("world", $nonce, $sk);
  $pt = secretbox_decrypt_detached($ct, $tag, $nonce, $sk);
  # $pt is now "world" (MemVault)

=head1 DESCRIPTION

Encrypts a message with a key and a nonce to keep it confidential.

Computes an authentication tag. This tag is used to make sure that the message
hasn't been tampered with before decrypting it.

A single key is used both to encrypt/authenticate and verify/decrypt messages.
For this reason, it is critical to keep the key confidential.

The nonce doesn't have to be confidential, but it should never ever be reused
with the same key. The easiest way to generate a nonce is to use
L</secretbox_nonce>.

Messages encrypted are assumed to be independent. If multiple messages are sent
using this API and random nonces, there will be no way to detect if a message
has been received twice, or if messages have been reordered. If this is a
requirement, see L<Crypt::Sodium::XS::secretstream>.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants as documented below. A separate import tag is provided for each of
the primitives listed in L</PRIMITIVES>. For example, C<:xchacha20poly1305>
imports C<secretbox_xchacha20poly1305_decrypt>. You should use at least one
import tag.

=head2 secretbox_decrypt

=head2 secretbox_E<lt>primitiveE<gt>_decrypt

  my $plaintext = secretbox_decrypt($ciphertext, $nonce, $key);

Croaks on decryption failure.

C<$ciphertext> is the combined ciphertext to decrypt.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</secretbox_NONCEBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</secretbox_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

B<NOTE>: this is the libsodium function C<crypto_secretbox_open_easy>. Its name
is slightly different for consistency of this API.

=head2 secretbox_decrypt_detached

=head2 secretbox_E<lt>primitiveE<gt>_decrypt_detached

  my $plaintext = secretbox_decrypt_detached($ciphertext, $tag, $nonce, $key);

Croaks on decryption failure.

C<$ciphertext> is the detached ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag. It must be
L</secretbox_MACBYTES> bytes.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</secretbox_NONCEBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</secretbox_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

B<NOTE>: this is the libsodium function C<crypto_secretbox_open_detached>. Its
name is slightly different for consistency of this API.

=head2 secretbox_encrypt

=head2 secretbox_E<lt>primitiveE<gt>_encrypt

  my $ciphertext = secretbox_encrypt($message, $nonce, $key);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</secretbox_NONCEBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</secretbox_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the encrypted ciphertext.

B<NOTE>: this is the libsodium function C<crypto_secretbox_easy>. Its name is
slightly different for consistency of this API.

=head2 secretbox_encrypt_detached

=head2 secretbox_E<lt>primitiveE<gt>_encrypt_detached

  my ($ciphertext, $tag) = secretbox_encrypt($message, $nonce, $key);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</secretbox_NONCEBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</secretbox_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the encrypted ciphertext and its authentication tag.

B<NOTE>: this is the libsodium function C<crypto_secretbox_detached>. Its name
is slightly different for consistency of this API.

=head2 secretbox_keygen

=head2 secretbox_E<lt>primitiveE<gt>_keygen

  my $key = secretbox_keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of
L</secretbox_KEYBYTES> bytes.

=head2 secretbox_nonce

=head2 secretbox_E<lt>primitiveE<gt>_nonce

  my $nonce = secretbox_nonce();
  my $nonce = secretbox_nonce($base);

C<$base> is optional. It must be less than or equal to L</secretbox_NONCEBYTES>
bytes. If not provided, the nonce will be random.

Returns a nonce of L</secretbox_NONCEBYTES> bytes.

=head1 CONSTANTS

=head2 secretbox_PRIMITIVE

  my $default_primitive = secretbox_PRIMITIVE();

Returns the name of the default primitive.

=head2 secretbox_NONCEBYTES

=head2 secretbox_E<lt>primitiveE<gt>_NONCEBYTES

  my $nonce_size = secretbox_NONCEBYTES();

Returns the size, in bytes, of a nonce.

=head2 secretbox_KEYBYTES

=head2 secretbox_E<lt>primitiveE<gt>_KEYBYTES

  my $key_size = secretbox_KEYBYTES();

Returns the size, in bytes, of a secret key.

=head2 secretbox_MACBYTES

=head2 secretbox_E<lt>primitiveE<gt>_MACBYTES

  my $tag_size = secretbox_MACBYTES();

Returns the size, in bytes, of an authentication tag.

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<secretbox_E<lt>primitiveE<gt>>-prefixed counterparts (e.g.,
secretbox_xchachapoly1305_verify).

=over 4

=item * xchacha20poly1305

=item * xsalsa20poly1305 (default)

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::secretbox>

=item L<https://doc.libsodium.org/secret-key_cryptography/secretbox>

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
