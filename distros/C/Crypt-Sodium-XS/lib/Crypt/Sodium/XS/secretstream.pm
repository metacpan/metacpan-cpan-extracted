package Crypt::Sodium::XS::secretstream;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  ABYTES
  HEADERBYTES
  KEYBYTES
  MESSAGEBYTES_MAX
  TAG_MESSAGE
  TAG_PUSH
  TAG_REKEY
  TAG_FINAL
);

my @bases = qw(
  init_decrypt
  init_encrypt
  keygen
);

# NB: no generic functions for secretstream

my $xchacha20poly1305 = [
  (map { "secretstream_xchacha20poly1305_$_" } @bases),
  (map { "secretstream_xchacha20poly1305_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all => [ @$xchacha20poly1305 ],
  xchacha20poly1305 => $xchacha20poly1305,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::secretstream - Secret key authenticated encryption for
multiple in-order messages

=head1 SYNOPSIS

  use Crypt::Sodium::XS::secretstream ":default";

  my $key = secretstream_xchacha20poly1305_keygen();

  # encryption
  my ($header, $stream_enc) = secretstream_xchacha20poly1305_init_encrypt($key);
  my $ciphertext = $stream_enc->encrypt("hello,");

  my $adata = "foo bar";
  my $ct2 = $stream_enc->encrypt(
    " world!",
    secretstream_xchacha20poly1305_TAG_PUSH,
    $adata
  );

  # decryption
  # note that $header (created above) is required to begin decryption.
  my $stream_dec = secretstream_xchacha20poly1305_init_decrypt($header, $key);
  my $plaintext = $stream_dec->decrypt($ciphertext);

  # note that $adata (created above) is required to decrypt successfully.
  my ($pt2, $tag) = $stream_dec->decrypt($ct2, $adata);
  if ($tag == secretstream_xchacha20poly1305_TAG_MESSAGE()) {
    # default, most common tag
    ...
  }
  elsif ($tag == secretstream_xchacha20poly1305_TAG_PUSH()) {
    # in-band mark for application to delimit related messages
    ...
  }
  elsif ($tag == secretstream_xchacha20poly1305_TAG_REKEY()) {
    # re-keying after this message triggered by sender
    ...
  }
  elsif ($tag == secretstream_xchacha20poly1305_TAG_FINAL()) {
    # last message
    ...
  }

=head1 DESCRIPTION

L<Crypt::Sodium::XS::secretstream> encrypts a sequence of messages, or a single
message split into an arbitrary number of chunks, using a secret key, with the
following properties:

=over 4

=item *

Messages cannot be truncated, removed, reordered, duplicated or modified
without this being detected by the decryption functions.

=item *

The same sequence encrypted twice will produce different ciphertexts.

=item *

An authentication tag is added to each encrypted message: stream corruption
will be detected early, without having to read the stream until the end.

=item *

Each message can include additional data (ex: timestamp, protocol version) in
the computation of the authentication tag.

=item *

Messages can have different sizes.

=item *

There are no practical limits to the total length of the stream, or to the
total number of individual messages.

=item *

Ratcheting: at any point in the stream, it is possible to "forget" the key used
to encrypt the previous messages, and switch to a new key.

=back

L<Crypt::Sodium::XS::secretstream> can be used to securely send an ordered
sequence of messages to a peer. Since the length of the stream is not limited,
it can also be used to encrypt files regardless of their size.

It transparently generates nonces and automatically handles key rotation.

=head1 FUNCTIONS

Nothing is exported by default. L<Crypt::Sodium::XS::secretstream>, like
libsodium, supports only the primitive-specific functions for one primitive
currently. There is a single C<:xchacha20poly1305> import tag for the functions
and constants listed below.

=head2 secretstream_xchacha20poly1305_init_decrypt

  my $stream_dec = secretstream_xchacha20poly1305_init_decrypt($header, $key);

B<NOTE>: this is the libsodium function
C<crypto_secretstream_xchacha20poly1305_init_pull>. Its name is slightly
different for consistency of this API.

=head2 secretstream_xchacha20poly1305_init_encrypt

  my ($header, $stream_enc) = secretstream_xchacha20poly1305_init_encrypt($key);

B<NOTE>: this is the libsodium function
C<crypto_secretstream_xchacha20poly1305_init_push>. Its name is slightly
different for consistency of this API.

=head2 secretstream_xchacha20poly1305_keygen

  my $key = secretstream_xchacha20poly1305_keygen();

=head1 STREAM INTERFACE

=head2 OVERVIEW

An encrypted stream starts with a short header, whose size is
L</secretstream_xchacha20poly1305_HEADERBYTES> bytes. That header must be
sent/stored before the sequence of encrypted messages, as it is required to
decrypt the stream. The header content doesn’t have to be secret and decryption
with a different header would fail.

A tag is attached to each message. That tag can be any of:

* 0, or L</secretstream_xchacha20poly1305_TAG_MESSAGE>: the most common tag,
  that doesn’t add any information about the nature of the message.

* L</secretstream_xchacha20poly1305_TAG_FINAL>: indicates that the message
  marks the end of the stream, and erases the secret key used to encrypt the
  previous sequence.

* L</secretstream_xchacha20poly1305_TAG_PUSH>: indicates that the message marks
  the end of a set of messages, but not the end of the stream. For example, a
  huge JSON string sent as multiple chunks can use this tag to indicate to the
  application that the string is complete and that it can be decoded. But the
  stream itself is not closed, and more data may follow.

* L</secretstream_xchacha20poly1305_TAG_REKEY>: “forget” the key used to
  encrypt this message and the previous ones, and derive a new secret key.

A typical encrypted stream simply attaches 0 as a tag to all messages, except
the last one which is tagged as TAG_FINAL.

Note that tags are encrypted; encrypted streams do not reveal any information
about sequence boundaries (PUSH and REKEY tags).

For each message, additional data can be included in the computation of the
authentication tag. With this API, additional data is rarely required, and most
applications can just use NULL and a length of 0 instead.

=head2 ENCRYPTION

The L</secretstream_xchacha20poly1305_init_encrypt> method returns a header and
a secretstream encryption object. This is an opaque object with the following
methods:

=over 4

=item encrypt

  my $ciphertext = $stream_enc->encrypt($plaintext, $tag, $adata);

C<$tag> is optional, and defaults to
L</secrestream_xchacha20poly1305_TAG_MESSAGE>. The most common use is a tag of
L</secretstream_xchacha20poly1305_TAG_FINAL> to indicate the last message in a
stream.

C<$adata> is optional. If provided, it must match the additional data that was
used when encrypting this message. It is rarely needed with the secretstream
interface.

=back

=head2 DECRYPTION

The L</init_decrypt> method is the decryption counterpart for the receiving end
of a stream. It takes a header and a secret key; the key must match the one
used to create the encryption object, and the header must match the one that
was returned when it was created.

Returns a secretstream decryption object. This is an opaque object with the
following methods:

=over 4

=item decrypt

  my $plaintext = $stream_dec->decrypt($ciphertext, $adata);
  my ($plaintext, $tag) = $stream_dec->decrypt($ciphertext, $adata);

Croaks on decryption failure.

C<$tag> will be one of the tags listed in L</CONSTANTS>; the tag used when
encrypting this message. The most common use is a tag of
L</secretstream_xchacha20poly1305_TAG_FINAL> indicating the last message of a
stream.

C<$adata> is optional. It is rarely needed with the secretstream interface.

=back

=head1 CONSTANTS

=head2 secretstream_PRIMITIVE

  my $default_primitive = secretstream_PRIMITIVE();

=head2 secretstream_ABYTES

  my $additional_data_length = secretstream_ABYTES();

This is not a restriction on the amount of additional data, it is the size of
the ciphertext MAC.

=head2 secretstream_HEADERBYTES

  my $header_length = secretstream_HEADERBYTES();

=head2 secretstream_KEYBYTES

  my $key_length = secretstream_KEYBYTES();

=head2 secretstream_MESSAGEBYTES_MAX

  my $message_max_length = secretstream_MESSAGEBYTES_MAX();

=head2 secretstream_TAG_MESSAGE

  my $message_tag = secretstream_TAG_MESSAGE();

=head2 secretstream_TAG_PUSH

  my $push_tag = secretstream_TAG_PUSH();

=head2 secretstream_TAG_REKEY

  my $rekey_tag = secretstream_TAG_REKEY();

=head2 secretstream_TAG_FINAL

  my $final_tag = secretstream_TAG_FINAL();

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<secretstream_E<lt>primitiveE<gt>>-prefixed counterparts (e.g.,
secretstream_xchacha20poly1305_init_decrypt,
secretstream_xchacha20poly1305_KEYBYTES).

=over 4

=item * xchacha20poly1305

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://doc.libsodium.org/secret-key_cryptography/secretstream>

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

For any security sensitive reports, please email the author directly or contact
privately via IRC.

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
