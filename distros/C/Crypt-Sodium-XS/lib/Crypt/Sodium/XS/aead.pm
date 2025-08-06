package Crypt::Sodium::XS::aead;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  ABYTES
  KEYBYTES
  MESSAGEBYTES_MAX
  NPUBBYTES
  NSECBYTES
);

my @bases = qw(
  decrypt
  decrypt_detached
  encrypt
  encrypt_detached
  keygen
  nonce
);

# NB: no generic functions for aead

my $chacha20poly1305 = [
  (map { "aead_chacha20poly1305_$_" } @bases),
  (map { "aead_chacha20poly1305_$_" } @constant_bases),
];

my $chacha20poly1305_ietf = [
  (map { "aead_chacha20poly1305_ietf_$_" } @bases),
  (map { "aead_chacha20poly1305_ietf_$_" } @constant_bases),
];

my $aes256gcm = [
  (map { "aead_aes256gcm_$_" } @bases, "beforenm"),
  (map { "aead_aes256gcm_$_" } @constant_bases),
];

my $xchacha20poly1305_ietf = [
  (map { "aead_xchacha20poly1305_ietf_$_" } @bases),
  (map { "aead_xchacha20poly1305_ietf_$_" } @constant_bases),
];

my $aegis128l = [
  (map { "aead_aegis128l_$_" } @bases),
  (map { "aead_aegis128l_$_" } @constant_bases),
];

my $aegis256 = [
  (map { "aead_aegis256_$_" } @bases),
  (map { "aead_aegis256_$_" } @constant_bases),
];

my $features = [qw[
  aead_aes256gcm_available
  aead_aegis_available
]];

our %EXPORT_TAGS = (
  all => [ @$chacha20poly1305, @$chacha20poly1305_ietf,
           @$aes256gcm, @$xchacha20poly1305_ietf,
           @$aegis128l, @$aegis256, @$features,
  ],
  chacha20poly1305 => $chacha20poly1305,
  chacha20poly1305_ietf => $chacha20poly1305_ietf,
  aes256gcm => $aes256gcm,
  xchacha20poly1305_ietf => $xchacha20poly1305_ietf,
  aegis128l => $aegis128l,
  aegis256 => $aegis256,
  features => $features,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::aead - Authenticated encryption with additional data

=head1 SYNOPSIS

  use Crypt::Sodium::XS::aead ":xchacha20poly1305";
  use Crypt::Sodium::XS::Util "sodium_increment";

  my $key = aead_xchacha20poly1305_ietf_keygen();
  my $nonce = aead_xchacha20poly1305_ietf_nonce();
  my $msg = "hello";

  # combined mode, authentication tag and ciphertext combined

  my $ciphtertext
    = aead_xchacha20poly1305_ietf_encrypt($msg, $nonce, $key);
  my $plaintext
    = aead_xchacha20poly1305_ietf_decrypt($ciphertext, $nonce, $key);
  # $plaintext eq $msg

  $nonce = sodium_increment($nonce);
  # NOTE: $adata is not confidential
  my $adata = "additional cryptographically validated data";

  $ciphtertext
    = aead_xchacha20poly1305_ietf_encrypt($msg, $nonce, $key, $adata);
  $plaintext
    = aead_xchacha20poly1305_ietf_decrypt($ciphertext, $nonce, $key, $adata);
  # $plaintext eq $msg and $adata is authentic

  # detached mode, authentication tag and ciphertext separate

  $nonce = sodium_increment($nonce);

  my ($ciphtertext, $tag) = aead_xchacha20poly1305_ietf_encrypt_detached(
    $msg,
    $nonce,
    $key,
    $adata
  );
  my $plaintext = aead_xchacha20poly1305_ietf_decrypt(
    $ciphertext,
    $tag,
    $nonce,
    $key,
    $adata
  );
  # $plaintext eq $msg and $adata is authentic

=head1 DESCRIPTION

L<Crypt::Sodium::XS::aead> encrypts a message with a key and a nonce to keep it
confidential.

L<Crypt::Sodium::XS::aead> computes an authentication tag. This tag is used to
make sure that the message, as well as optional, non-confidential
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

=head1 FUNCTIONS

Nothing is exported by default. A C<:features> tag imports the C<*_available>
feature test functions. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<aead_E<lt>primitiveE<gt>_*> functions and constants for that primitive. A
C<:all> tag imports everything.

B<Note>: L<Crypt::Sodium::XS::aead>, like libsodium, does not provide generic
functions for AEAD. Only the primitive-specific functions are available, so
there is no C<:default> tag.

=head2 aead_aes256gcm_available

  my $has_aes256gcm = aead_aes256gcm_available();

Returns true if the current environment supports the C<aes256gcm> primitive,
false otherwise.

=head2 aead_aegis_available

  my $has_aegis = aead_aegis_available();

Returns true if L<Crypt::Sodium::XS> supports AEGIS primitives, false
otherwise. AEGIS will only be supported if L<Crypt::Sodium::XS> was built with
a new enough version of libsodium headers. A newer dynamic library at runtime
will not enable support.

=head2 aead_aes256gcm_beforenm

  my $precalc = aead_aes256gcm_beforenm($key, $flags);

B<Note>: Available for the aes256gcm primitive only.

C<$key> is the secret key used by the precalculation object. It must be
L</aead_aes256gcm_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the precalculation protected
memory object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a precalculation aead object. This
is useful when performing many operations with the same key. See
L</PRECALCULATION INTERFACE>.

=head2 aead_E<lt>primitiveE<gt>_decrypt

  my $plaintext = aead_xchacha20poly1305_ietf_decrypt(
                    $ciphertext, $nonce, $key, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the combined ciphertext to decrypt.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=head2 aead_E<lt>primitiveE<gt>_decrypt_detached

  my $plaintext = aead_chacha20poly1305_decrypt_detached(
                    $ciphertext, $tag, $nonce, $key, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the detached ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=head2 aead_E<lt>primitiveE<gt>_encrypt

  my $ciphertext
    = aead_chacha20poly1305_ietf_encrypt($plaintext, $nonce, $key, $adata);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the combined encrypted ciphertext.

=head2 aead_E<lt>primitiveE<gt>_encrypt_detached

  my ($ciphertext, $tag)
    = aead_aes256gcm_encrypt_detached($plaintext, $nonce, $key, $adata);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$key> is the secret used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the detached encrypted ciphertext and its authentication tag.

=head2 aead_E<lt>primitiveE<gt>_keygen

  my $key = aead_xchacha20poly1305_ietf_keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a new secret key of
L</aead_E<lt>primitiveE<gt>_KEYBYTES> bytes.

=head2 aead_E<lt>primitiveE<gt>_nonce

  my $nonce = aead_xchacha20poly1305_ietf_nonce($base);

C<$base> is optional. It must be less than or equal to
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes. If not provided, the nonce will
be random.

Returns a nonce of L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

B<NOTE>: chacha20poly1305 and aes256gcm should *not* be used with only random
nonces, as they have a short nonce and collisions are a risk. For those
primitives, you can still generate a random nonce with this function, but you
should then use L<Crypt::Sodium::XS::Util/sodium_increment> to get a new nonce
for each message.

=head1 PRECALCULATION INTERFACE

Only available for aes256gcm.

Applications that encrypt several messages using the same key can gain a little
speed by expanding the AES key only once, via the precalculation interface.

A precalculated aead object is created by calling the L</aead_beforenm>
function. It is an opaque object which provides the following methods:

=over

=item decrypt

  my $plaintext = $precalc->decrypt($ciphertext, $nonce, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the combined ciphertext to decrypt.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=item decrypt_detached

  my $plaintext
    = $precalc->decrypt_detached($ciphertext, $tag, $nonce, $adata, $flags);

Croaks on decryption failure.

C<$ciphertext> is the detached ciphertext to decrypt.

C<$tag> is the ciphertext's authentication tag.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$key> is the secret key used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$adata> is optional. See notes in L</DESCRIPTION>.

C<$flags> is optional. It is the flags used for the C<$plaintext>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: the decrypted plaintext.

=item encrypt

  my $ciphertext = $precalc->encrypt($plaintext, $nonce, $adata);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the combined encrypted ciphertext.

=item encrypt_detached

  my ($ciphertext, $tag) = $precalc->encrypt($plaintext, $nonce, $adata);

C<$plaintext> is the plaintext to encrypt. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$nonce> is the nonce used to encrypt the ciphertext. It must be
L</aead_E<lt>primitiveE<gt>_NPUBBYTES> bytes.

C<$adata> is optional. See notes in L</DESCRIPTION>.

Returns the detached encrypted ciphertext and its authentication tag.

=back

=head1 CONSTANTS

=head2 aead_E<lt>primitiveE<gt>_ABYTES

  my $tag_size = aead_chacha20poly1305_ABYTES();

Returns the size, in bytes, of the ciphertext authentication tag. Note that
this is B<not> a size restriction on the amount of additional data (adata).

The size of any combined (not detached) ciphertext is message size +
L</aead_E<lt>primitiveE<gt>_ABYTES>.

=head2 aead_E<lt>primitiveE<gt>_KEYBYTES

  my $key_size = aead_chacha20poly1305_ietf_KEYBYTES();

Returns the size, in bytes, of a secret key.

=head2 aead_E<lt>primitiveE<gt>_MESSAGEBYTES_MAX

  my $message_max_size = aead_aes256gcm_MESSAGEBYTES_MAX();

Returns the maxmimum size, in bytes, of any message to be encrypted.

=head2 aead_E<lt>primitiveE<gt>_NPUBBYTES

  my $nonce_size = aead_xchacha20poly1305_ietf_NPUBBYTES();

Returns the size, in bytes, of a nonce.

=head1 PRIMITIVES

All functions have C<aead_E<lt>primitiveE<gt>>-prefixed couterparts (e.g.,
aead_xchacha20poly1305_encrypt, aead_chacha20poly1305_ietf_ABYTES).

=over 4

=item * chacha20poly1305

=item * chacha20poly1305_ietf

=item * xchacha20poly1305_ietf

=item * aes256gcm

Check L</aead_aes256gcm_available> to see if this primitive can be used.

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

=item * aegis128l

Check L</aead_aegis_available> to see if this primitive can be used.

=item * aegis256

Check L</aead_aegis_available> to see if this primitive can be used.

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::aead>

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
