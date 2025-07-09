package Crypt::Sodium::XS::OO::secretstream;
use strict;
use warnings;

use Crypt::Sodium::XS::secretstream;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  xchacha20poly1305 => {
    ABYTES => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_ABYTES,
    HEADERBYTES => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_HEADERBYTES,
    KEYBYTES => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_KEYBYTES,
    MESSAGEBYTES_MAX => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_MESSAGEBYTES_MAX,
    PRIMITIVE => sub { 'xchacha20poly1305' },
    TAG_MESSAGE => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_TAG_MESSAGE,
    TAG_PUSH => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_TAG_PUSH,
    TAG_REKEY => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_TAG_REKEY,
    TAG_FINAL => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_TAG_FINAL,
    init_decrypt => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_init_decrypt,
    init_encrypt => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_init_encrypt,
    keygen => \&Crypt::Sodium::XS::secretstream::secretstream_xchacha20poly1305_keygen,
  },
);

sub primitives { keys %methods }

sub ABYTES { my $self = shift; goto $methods{$self->{primitive}}->{ABYTES}; }
sub HEADERBYTES { my $self = shift; goto $methods{$self->{primitive}}->{HEADERBYTES}; }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub MESSAGEBYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{MESSAGEBYTES_MAX}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub TAG_MESSAGE { my $self = shift; goto $methods{$self->{primitive}}->{TAG_MESSAGE}; }
sub TAG_PUSH { my $self = shift; goto $methods{$self->{primitive}}->{TAG_PUSH}; }
sub TAG_REKEY { my $self = shift; goto $methods{$self->{primitive}}->{TAG_REKEY}; }
sub TAG_FINAL { my $self = shift; goto $methods{$self->{primitive}}->{TAG_FINAL}; }
sub init_decrypt { my $self = shift; goto $methods{$self->{primitive}}->{init_decrypt}; }
sub init_pull { my $self = shift; goto $methods{$self->{primitive}}->{init_decrypt}; }
sub init_encrypt { my $self = shift; goto $methods{$self->{primitive}}->{init_encrypt}; }
sub init_push { my $self = shift; goto $methods{$self->{primitive}}->{init_encrypt}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::secretstream - Secret key authenticated encryption for
multiple in-order messages

=head1 SYNOPSIS

  use Crypt::Sodium::XS::secretstream;
  my $sstream
    = Crypt::Sodium::XS::OO::secretstream->new(primitive => 'xchacha20poly1305');
  # or use the shortcut
  # use Crypt::Sodium::XS;
  # my $sstream
  #   = Crypt::Sodium::XS->secretstream(primitive => 'xchacha20poly1305');

  # typically, key exchange would be used for a shared secret key.
  my $key = $sstream->keygen;

  # encryption
  my ($header, $sstream_enc) = $sstream->init_encrypt($key);
  my $ciphertext = $sstream_enc->encrypt("hello,");

  my $adata = "foo bar";
  my $ct2 = $sstream_enc->encrypt(" world!", $sstream->TAG_PUSH, $adata);

  # decryption
  # note that $header (created above) is required to begin decryption.
  my $sstream_dec = $sstream->init_decrypt($header, $key);
  my $plaintext = $sstream_dec->decrypt($ciphertext);

  # note that $adata (created above) is required to decrypt this message.
  my ($pt2, $tag) = $sstream_dec->decrypt($ct2, $adata);

  # using tags
  if ($tag == $sstream->TAG_MESSAGE) {
    # default, most common tag
  }
  elsif ($tag == $sstream->TAG_PUSH) {
    # in-band mark for application to delimit related messages
  }
  elsif ($tag == $sstream->TAG_REKEY) {
    # re-keying after this message was triggered by sender
  }
  elsif ($tag == $sstream->TAG_FINAL) {
    # last message
  }

=head1 DESCRIPTION

L<Crypt::Sodium::XS::OO::secretstream> encrypts a sequence of messages, or a
single message split into an arbitrary number of chunks, using a secret key,
with the following properties:

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

=head1 CONSTRUCTOR

=head2 new

  my $sstream
    = Crypt::Sodium::XS::OO::secretstream->new(primitive => 'xchacha20poly1305');
  my $sstream
    = Crypt::Sodium::XS->secretstream(primitive => 'xchacha20poly1305');

Returns a new secretstream object for the given primitive. The primitive
argument is required.

=head1 METHODS

=head2 PRIMITIVE

  my $default_primitive = $sstream->PRIMITIVE;

=head2 ABYTES

  my $additional_data_length = $sstream->ABYTES;

This is not a restriction on the amount of additional data, it is the size of
the ciphertext MAC.

=head2 HEADERBYTES

  my $header_length = $sstream->HEADERBYTES;

=head2 KEYBYTES

  my $key_length = $sstream->KEYBYTES;

=head2 MESSAGEBYTES_MAX

  my $message_max_length = $sstream->MESSAGEBYTES_MAX;

=head2 TAG_MESSAGE

  my $message_tag = $sstream->TAG_MESSAGE;

=head2 TAG_PUSH

  my $push_tag = $sstream->TAG_PUSH;

=head2 TAG_REKEY

  my $rekey_tag = $sstream->TAG_REKEY;

=head2 TAG_FINAL

  my $final_tag = $sstream->TAG_FINAL;

=head2 primitives

  my @primitives = $sstream->primitives;

Returns a list of all supported primitive names.

=head2 init_decrypt

  my $sstream_dec = $sstream->init_decrypt($header, $key);

See L</STREAM INTERFACE>.

=head2 init_encrypt

  my ($header, $sstream_enc) = $sstream->init_encrypt($key);

See L</STREAM INTERFACE>.

=head2 keygen

  my $key = $sstream->keygen;

=head1 STREAM INTERFACE

=head2 OVERVIEW

An encrypted stream starts with a short header, whose size is L</HEADERBYTES>
bytes. That header must be sent/stored before the sequence of encrypted
messages, as it is required to decrypt the stream. The header content doesn’t
have to be secret and decryption with a different header would fail.

A tag is attached to each message. That tag can be any of:

* 0, or L</TAG_MESSAGE>: the most common tag, that doesn’t add any information
  about the nature of the message.

* L</TAG_FINAL>: indicates that the message marks the end of the stream, and
  erases the secret key used to encrypt the previous sequence.

* L</TAG_PUSH>: indicates that the message marks the end of a set of messages,
  but not the end of the stream. For example, a huge JSON string sent as
  multiple chunks can use this tag to indicate to the application that the
  string is complete and that it can be decoded. But the stream itself is not
  closed, and more data may follow.

* L</TAG_REKEY>: “forget” the key used to encrypt this message and the previous
  ones, and derive a new secret key.

A typical encrypted stream simply attaches 0 as a tag to all messages, except
the last one which is tagged as TAG_FINAL.

Note that tags are encrypted; encrypted streams do not reveal any information
about sequence boundaries (PUSH and REKEY tags).

For each message, additional data can be included in the computation of the
authentication tag. With this API, additional data is rarely required, and most
applications can just use NULL and a length of 0 instead.

=head2 ENCRYPTION

The L</init_encrypt> method takes a shared secret key returns a header and a
secretstream encryption object. This is an opaque object with the following
methods:

=over 4

=item encrypt

  my $ciphertext = $sstream_enc->encrypt($plaintext, $tag, $adata);

C<$tag> is optional, and defaults to L</TAG_MESSAGE>. The most common use is a
tag of L</TAG_FINAL> to indicate the last message in a stream.

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

  my $plaintext = $sstream_dec->decrypt($ciphertext, $adata);
  my ($plaintext, $tag) = $sstream_dec->decrypt($ciphertext, $adata);

Croaks on decryption failure.

C<$tag> will be one of the tags listed in L</CONSTANTS>; the tag used when
encrypting this message. The most common use is a tag of
L</TAG_FINAL> indicating the last message of a stream.

C<$adata> is optional. It is rarely needed with the secretstream interface.

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

=head1 AUTHOR

Brad Barden E<lt>perlmodules@5c30.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2022 Brad Barden. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
