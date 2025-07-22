package Crypt::Sodium::XS::OO::aead;
use strict;
use warnings;

use Crypt::Sodium::XS::aead;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  chacha20poly1305 => {
    ABYTES => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ABYTES,
    KEYBYTES => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_MESSAGEBYTES_MAX,
    NPUBBYTES => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_NPUBBYTES,
    PRIMITIVE => sub { 'chacha20poly1305' },
    beforenm => sub { die "beforenm is only supported for the aes256gcm primitive" },
    decrypt => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_decrypt,
    decrypt_detached => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_decrypt_detached,
    encrypt => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_encrypt_detached,
    keygen => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_keygen,
    nonce => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_nonce,
  },
  chacha20poly1305_ietf => {
    ABYTES => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_ABYTES,
    KEYBYTES => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_MESSAGEBYTES_MAX,
    NPUBBYTES => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_NPUBBYTES,
    PRIMITIVE => sub { 'chacha20poly1305_ietf' },
    beforenm => sub { die "beforenm is only supported for the aes256gcm primitive" },
    decrypt => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_decrypt,
    decrypt_detached => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_decrypt_detached,
    encrypt => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_encrypt_detached,
    keygen => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_keygen,
    nonce => \&Crypt::Sodium::XS::aead::aead_chacha20poly1305_ietf_nonce,
  },
  Crypt::Sodium::XS::aead::aead_aegis_available() ? (
    aegis128l => {
      ABYTES => \&Crypt::Sodium::XS::aead::aead_aegis128l_ABYTES,
      KEYBYTES => \&Crypt::Sodium::XS::aead::aead_aegis128l_KEYBYTES,
      MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::aead::aead_aegis128l_MESSAGEBYTES_MAX,
      NPUBBYTES => \&Crypt::Sodium::XS::aead::aead_aegis128l_NPUBBYTES,
      PRIMITIVE => sub { 'aegis128l' },
      beforenm => sub { die "beforenm is only supported for the aes256gcm primitive" },
      decrypt => \&Crypt::Sodium::XS::aead::aead_aegis128l_decrypt,
      decrypt_detached => \&Crypt::Sodium::XS::aead::aead_aegis128l_decrypt_detached,
      encrypt => \&Crypt::Sodium::XS::aead::aead_aegis128l_encrypt,
      encrypt_detached => \&Crypt::Sodium::XS::aead::aead_aegis128l_encrypt_detached,
      keygen => \&Crypt::Sodium::XS::aead::aead_aegis128l_keygen,
      nonce => \&Crypt::Sodium::XS::aead::aead_aegis128l_nonce,
    },
    aegis256 => {
      ABYTES => \&Crypt::Sodium::XS::aead::aead_aegis256_ABYTES,
      KEYBYTES => \&Crypt::Sodium::XS::aead::aead_aegis256_KEYBYTES,
      MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::aead::aead_aegis256_MESSAGEBYTES_MAX,
      NPUBBYTES => \&Crypt::Sodium::XS::aead::aead_aegis256_NPUBBYTES,
      PRIMITIVE => sub { 'aegis256' },
      beforenm => sub { die "beforenm is only supported for the aes256gcm primitive" },
      decrypt => \&Crypt::Sodium::XS::aead::aead_aegis256_decrypt,
      decrypt_detached => \&Crypt::Sodium::XS::aead::aead_aegis256_decrypt_detached,
      encrypt => \&Crypt::Sodium::XS::aead::aead_aegis256_encrypt,
      encrypt_detached => \&Crypt::Sodium::XS::aead::aead_aegis256_encrypt_detached,
      keygen => \&Crypt::Sodium::XS::aead::aead_aegis256_keygen,
      nonce => \&Crypt::Sodium::XS::aead::aead_aegis256_nonce,
    },
  ) : (),
  Crypt::Sodium::XS::aead::aead_aes256gcm_available() ? (
    aes256gcm => {
      ABYTES => \&Crypt::Sodium::XS::aead::aead_aes256gcm_ABYTES,
      KEYBYTES => \&Crypt::Sodium::XS::aead::aead_aes256gcm_KEYBYTES,
      MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::aead::aead_aes256gcm_MESSAGEBYTES_MAX,
      NPUBBYTES => \&Crypt::Sodium::XS::aead::aead_aes256gcm_NPUBBYTES,
      PRIMITIVE => sub { 'aes256gcm' },
      beforenm => \&Crypt::Sodium::XS::aead::aead_aes256gcm_beforenm,
      decrypt => \&Crypt::Sodium::XS::aead::aead_aes256gcm_decrypt,
      decrypt_detached => \&Crypt::Sodium::XS::aead::aead_aes256gcm_decrypt_detached,
      encrypt => \&Crypt::Sodium::XS::aead::aead_aes256gcm_encrypt,
      encrypt_detached => \&Crypt::Sodium::XS::aead::aead_aes256gcm_encrypt_detached,
      keygen => \&Crypt::Sodium::XS::aead::aead_aes256gcm_keygen,
      nonce => \&Crypt::Sodium::XS::aead::aead_aes256gcm_nonce,
    },
  ) : (),
  xchacha20poly1305_ietf => {
    ABYTES => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_ABYTES,
    KEYBYTES => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_MESSAGEBYTES_MAX,
    NPUBBYTES => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_NPUBBYTES,
    PRIMITIVE => sub { 'xchacha20poly1305_ietf' },
    beforenm => sub { die "beforenm is only supported for the aes256gcm primitive" },
    decrypt => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_decrypt,
    decrypt_detached => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_decrypt_detached,
    encrypt => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_encrypt,
    encrypt_detached => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_encrypt_detached,
    keygen => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_keygen,
    nonce => \&Crypt::Sodium::XS::aead::aead_xchacha20poly1305_ietf_nonce,
  },
);

sub primitives { keys %methods }

sub aes256gcm_available { goto \&Crypt::Sodium::XS::aead::aead_aes256gcm_available }
sub aegis_available { goto \&Crypt::Sodium::XS::aead::aead_aegis_available }

sub ABYTES { my $self = shift; goto $methods{$self->{primitive}}->{ABYTES}; }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub MESSAGEBYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{MESSAGEBYTES_MAX}; }
sub NPUBBYTES { my $self = shift; goto $methods{$self->{primitive}}->{NPUBBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub beforenm { my $self = shift; goto $methods{$self->{primitive}}->{beforenm}; }
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

Crypt::Sodium::XS::OO::aead - Authenticated encryption with additional data

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  use Crypt::Sodium::XS::Util "sodium_increment";

  my $aead = Crypt::Sodium::XS->aead(primitive => 'xchacha20poly1305_ietf');
  $aead->primitive('aegis256') if $aead->has_aegis;

  my $key = $aead->keygen;
  my $nonce = $aead->nonce;
  my $msg = "hello";

  # combined mode, authentication tag and ciphertext combined

  my $ciphtertext = $aead->encrypt($msg, $nonce, $key);
  my $plaintext = $aead->decrypt($ciphertext, $nonce, $key);
  # $plaintext eq $msg

  $nonce = sodium_increment($nonce);
  # NOTE: $adata is not confidential
  my $adata = "additional cryptographically validated data";

  $ciphtertext = $aead->encrypt($msg, $nonce, $key, $adata);
  $plaintext = $aead->decrypt($ciphertext, $nonce, $key, $adata);
  # $plaintext eq $msg and $adata is authentic

  # detached mode, authentication tag and ciphertext separate

  $nonce = sodium_increment($nonce);

  my ($ciphtertext, $tag)
    = $aead->encrypt_detached($msg, $nonce, $key, $adata);
  my $plaintext
    = $aead->decrypt($ciphertext, $tag, $nonce, $key, $adata);
  # $plaintext eq $msg and $adata is authentic

=head1 DESCRIPTION

L<Crypt::Sodium::XS::OO::aead> encrypts a message with a key and a nonce to
keep it confidential.

L<Crypt::Sodium::XS::OO::aead> computes an authentication tag. This tag is used
to make sure that the message, as well as optional, non-confidential
(non-encrypted) data haven't been tampered with.

These functions accept an optional, arbitrary long "additional data" (C<$adata>
below) parameter. These data are not present in the ciphertext, but are mixed
in the computation of the authentication tag. A typical use for these data is
to authenticate version numbers, timestamps or monotonically increasing
counters in order to discard previous messages and prevent replay attacks. It
can also be used to to authenticate protocol-specific metadata about the
message, such as its length and encoding, or other arbitrary non-confidential
headers. The additional data must then be provided to the decryption functions
(as C<$adata>) to successfully decrypt.

=head1 CONSTRUCTOR

=head2 new

  my $aead
    = Crypt::Sodium::XS::OO::aead->new(primitive => 'xchacha20poly1305_ietf');
  my $aead
    = Crypt::Sodium::XS->aead(primitive => 'xchacha20poly1305_ietf');

Returns a new aead object for the given primitive. The primitive argument is
required.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $aead->primitive;
  $aead->primitive('aegis256');

Gets or sets the primitive used for all operations by this object. For this
module, the returned primitive is always identical to L</PRIMITIVE>.

=head1 METHODS

=head2 aes256gcm_available

  my $has_aes256gcm = Crypt::Sodium::XS::OO::aead->aes256gcm_available;
  my $has_aes256gcm = $aead->aes256gcm_available;

Returns true if the current environment supports the C<aes256gcm> primitive,
false otherwise.

Can be called as a class method.

=head2 aegis_available

  my $has_aegis = Crypt::Sodium::XS::OO::aead->aegis_available;
  my $has_aegis = $aead->aegis_available;

Returns true if L<Crypt::Sodium::XS> supports AEGIS primitives, false
otherwise. AEGIS will only be supported if L<Crypt::Sodium::XS> was built with
a new enough version of libsodium headers. A newer dynamic library at runtime
will not enable support.

Can be called as a class method.

=head2 primitives

  my @primitives = Crypt::Sodium::XS::OO::aead->primitives
  my @primitives = $aead->primitives

Returns a list of all supported primitive names.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $aead->PRIMITIVE;

Returns the primitive used for all operations by this object. For this module,
always identical to the L</primitive> attribute.

=head2 beforenm

  my $precalc = $aead->beforenm($key, $flags);

B<Note>: Available for the aes256gcm primitive only.

C<$key> is the secret key used by the precalculation object. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the precalculation protected
memory object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a precalculation aead object. This
is useful when performing many operations with the same key. See
L</PRECALCULATION INTERFACE>.

=head2 decrypt

  my $plaintext = $aead->decrypt($ciphertext, $nonce, $key, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the combined ciphertext to decrypt.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NPUBBYTES>
bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=head2 decrypt_detached

  my $plaintext
    = $aead->decrypt_detached($ciphertext, $tag, $nonce, $key, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the detached ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag. It must be L</ABYTES> bytes.

C<$nonce> is the nonce used to encrypt the ciphertext.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::Protmem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=head2 encrypt

  my $ciphertext = $aead->encrypt($plaintext, $nonce, $key, $adata);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NPUBBYTES>
bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the combined encrypted ciphertext.

=head2 encrypt_detached

  my ($ciphertext, $tag)
    = $aead->encrypt_detached($plaintext, $nonce, $key, $adata);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NPUBBYTES>
bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the detached encrypted ciphertext and its authentication tag.

=head2 keygen

  my $key = $aead->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a new secret key of L</KEYBYTES>
bytes.

=head2 nonce

  my $nonce = $aead->nonce($base);

C<$base> is optional. It must be less than or equal to L</NPUBBYTES> bytes. If
not provided, the nonce will be random.

Returns a nonce of L</NPUBBYTES> bytes.

B<NOTE>: chacha20poly1305 and aes256gcm should *not* be used with only random
nonces, as they have a short nonce and collisions are a risk. For those
primitives, you can still generate a random nonce with this function, but you
should then use L<Crypt::Sodium::XS/sodium_increment> to get a new nonce for
each message.

=head2 ABYTES

  my $tag_size = $aead->ABYTES;

Returns the size, in bytes, of the authentication tag. Note that this is B<not>
a size restriction on the amount of additional data (adata).

The size of any combined (not detached) ciphertext is message size +
L</ABYTES>.

=head2 KEYBYTES

  my $key_size = $aead->KEYBYTES;

Returns the size, in bytes, of a secret key.

=head2 MESSAGEBYTES_MAX

  my $message_max_size = $aead->MESSAGEBYTES_MAX;

Returns the size, in bytes, of the maximum size of any message to be encrypted.

=head2 NPUBBYTES

  my $nonce_size = $aead->NPUBBYTES;

Returns the size, in bytes, of a nonce.

=head1 PRECALCULATION INTERFACE

Only available for aes256gcm.

Applications that encrypt several messages using the same key can gain a little
speed by expanding the AES key only once, via the precalculation interface.

A precalculated aead object is created by calling the L</beforenm> method. It
is an opaque object which provides the following methods:

=over 4

=item decrypt

  my $plaintext = $precalc->decrypt($ciphertext, $nonce, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the detached ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag. It must be L</ABYTES> bytes.

C<$nonce> is the nonce used to encrypt the ciphertext.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=item decrypt_detached

  my $plaintext
    = $precalc->decrypt_detached($ciphertext, $tag, $nonce, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the detached ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag. It must be L</ABYTES> bytes.

C<$nonce> is the nonce used to encrypt the ciphertext.

C<$key> is the secret key used to encrypt the ciphertext. It must be
C</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=item encrypt

  my $ciphertext = $precalc->encrypt($plaintext, $nonce, $adata, $flags);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NPUBBYTES>
bytes.

C<$key> is the secret with which to encrypt the plaintext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the combined encrypted ciphertext.

=item encrypt_detached

  my ($ciphertext, $tag)
    = $precalc->encrypt_detached($plaintext, $nonce, $adata, $flags);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be L</NPUBBYTES>
bytes.

C<$key> is the secret with which to encrypt the plaintext. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the detached encrypted ciphertext and its authentication tag.

=back

=head1 IMPORTANT NOTE ON aes256gcm

B<Warning>: Despite being the most popular AEAD construction due to its use in
TLS, safely using AES-GCM in a different context is tricky.

No more than ~ 350 GB of input data should be encrypted with a given key. This
is for ~ 16 KB messages -- Actual figures vary according to message sizes.

In addition, nonces are short and repeated nonces would totally destroy the
security of this scheme. Nonces should thus come from atomic counters, which
can be difficult to set up in a distributed environment.

Unless you absolutely need AES-GCM, use xchacha20poly1305_ietf (this is the
default) instead. It doesn't have any of these limitations.

Or, if you don't need to authenticate additional data, just stick to
L<Crypt::Sodium::XS::secretbox>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::aead>

=item L<Crypt::Sodium::XS::secretbox>

=item L<Crypt::Sodium::XS::secretstream>

=item L<https://doc.libsodium.org/secret-key_cryptography/aead>

=item L<https://doc.libsodium.org/secret-key_cryptography/encrypted-messages>

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
