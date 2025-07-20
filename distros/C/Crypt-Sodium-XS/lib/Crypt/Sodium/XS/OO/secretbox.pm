package Crypt::Sodium::XS::OO::secretbox;
use warnings;
use strict;

use Crypt::Sodium::XS::secretbox;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    KEYBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_KEYBYTES,
    NONCEBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_NONCEBYTES,
    MACBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_MACBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::secretbox::secretbox_PRIMITIVE,
    nonce => \&Crypt::Sodium::XS::secretbox::secretbox_nonce,
    keygen => \&Crypt::Sodium::XS::secretbox::secretbox_keygen,
    encrypt => \&Crypt::Sodium::XS::secretbox::secretbox_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::secretbox::secretbox_encrypt_detached,
    decrypt => \&Crypt::Sodium::XS::secretbox::secretbox_decrypt,
    decrypt_detached => \&Crypt::Sodium::XS::secretbox::secretbox_decrypt_detached,
  },
  xchacha20poly1305 => {
    KEYBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_KEYBYTES,
    NONCEBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_NONCEBYTES,
    MACBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_MACBYTES,
    PRIMITIVE => sub { 'xchacha20poly1305' },
    nonce => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_nonce,
    keygen => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_keygen,
    encrypt => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_encrypt_detached,
    decrypt => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_decrypt,
    decrypt_detached => \&Crypt::Sodium::XS::secretbox::secretbox_xchacha20poly1305_decrypt_detached,
  },
  xsalsa20poly1305 => {
    KEYBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_KEYBYTES,
    NONCEBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_NONCEBYTES,
    MACBYTES => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_MACBYTES,
    PRIMITIVE => sub { 'xsalsa20poly1305' },
    nonce => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_nonce,
    keygen => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_keygen,
    encrypt => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_encrypt_detached,
    decrypt => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_decrypt,
    decrypt_detached => \&Crypt::Sodium::XS::secretbox::secretbox_xsalsa20poly1305_decrypt_detached,
  },
);

sub primitives { keys %methods }

sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub NONCEBYTES { my $self = shift; goto $methods{$self->{primitive}}->{NONCEBYTES}; }
sub MACBYTES { my $self = shift; goto $methods{$self->{primitive}}->{MACBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub decrypt { my $self = shift; goto $methods{$self->{primitive}}->{decrypt}; }
sub decrypt_detached { my $self = shift; goto $methods{$self->{primitive}}->{decrypt_detached}; }
sub encrypt { my $self = shift; goto $methods{$self->{primitive}}->{encrypt}; }
sub encrypt_detached { my $self = shift; goto $methods{$self->{primitive}}->{encrypt_detached}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub nonce { my $self = shift; goto $methods{$self->{primitive}}->{nonce}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::secretbox - Secret key authenticated encryption

=head1 SYNOPSIS

  use Crypt::Sodium::XS::OO::secretbox;
  my $sbox = Crypt::Sodium::XS::OO::secretbox->new;
  # or use the shortcut
  # use Crypt::Sodium::XS;
  # my $sbox = Crypt::Sodium::XS->secretbox;
  use Crypt::Sodium::XS "sodium_increment";

  my $sk = $sbox->keygen;
  my $nonce = $sbox->nonce;

  my $ct = $sbox->encrypt("hello", $nonce, $sk);
  my $pt = $sbox->decrypt($ct, $nonce, $sk);
  # $pt is now "hello" (MemVault)

  $nonce = sodium_increment($nonce);
  ($ct, my $tag) = $sbox->encrypt_detached("world", $nonce, $sk);
  $pt = $sbox->decrypt_detached($ct, $tag, $nonce, $sk);
  # $pt is now "world" (MemVault)

=head1 DESCRIPTION

Encrypts a message with a key and a nonce to keep it confidential.

Computes an authentication tag. This tag is used to make sure that the message
hasn't been tampered with before decrypting it.

A single key is used both to encrypt/authenticate and verify/decrypt messages.
For this reason, it is critical to keep the key confidential.

The nonce doesn't have to be confidential, but it should never ever be reused
with the same key. The easiest way to generate a nonce is to use
L</nonce>.

Messages encrypted are assumed to be independent. If multiple messages are sent
using this API and random nonces, there will be no way to detect if a message
has been received twice, or if messages have been reordered. If this is a
requirement, see L<Crypt::Sodium::XS::secretstream>.

=head1 CONSTRUCTOR

=head2 new

  my $sbox = Crypt::Sodium::XS::OO::secretbox->new;
  my $sbox
    = Crypt::Sodium::XS::OO::secretbox->new(primitive => 'xsalsa20poly1305');
  my $sbox = Crypt::Sodium::XS->secretbox;

Returns a new secretbox object for the given primitive. If not given, the
default primitive is C<default>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $sbox->primitive;
  $sbox->primitive('poly1305');

Gets or sets the primitive used for all operations by this object. Note this
can be C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = Crypt::Sodium::XS::OO::secretbox->primitives;
  my @primitives = $sbox->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $sbox->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 decrypt

  my $plaintext = $sbox->decrypt($ciphertext, $nonce, $key, $flags);

Croaks on decryption failure.

C<$ciphertext> is the combined ciphertext to decrypt.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NONCEBYTES>
bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=head2 decrypt_detached

  my $plaintext
    = $sbox->decrypt_detached($ciphertext, $tag, $nonce, $key, $flags);

Croaks on decryption failure.

C<$ciphertext> is the detached ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag. It must be L</MACBYTES> bytes.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NONCEBYTES>
bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=head2 encrypt

  my $ciphertext = $sbox->encrypt($message, $nonce, $key);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NONCEBYTES>
bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the encrypted ciphertext.

=head2 encrypt_detached

  my ($ciphertext, $tag) = $sbox->encrypt($message, $nonce, $key);

C<$message> is the message to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NONCEBYTES>
bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the encrypted ciphertext and its authentication tag.

=head2 keygen

  my $key = $sbox->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of L</KEYBYTES> bytes.

=head2 nonce

  my $nonce = $sbox->nonce;
  my $nonce = $sbox->nonce($base);

C<$base> is optional. It must be less than or equal to L</NONCEBYTES> bytes. If
not provided, the nonce will be random.

Returns a nonce of L</NONCEBYTES> bytes.

=head2 NONCEBYTES

  my $nonce_size = $sbox->NONCEBYTES;

Returns the size, in bytes, of a nonce.

=head2 KEYBYTES

  my $key_size = $sbox->KEYBYTES;

Returns the size, in bytes, of a secret key.

=head2 MACBYTES

  my $tag_size = $sbox->MACBYTES;

Returns the size, in bytes, of an authentication tag.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::secretbox>

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
