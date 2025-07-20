package Crypt::Sodium::XS::auth;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  BYTES
  KEYBYTES
);

my @bases = qw(
  init
  keygen
  verify
);

my $default = [
  "auth",
  (map { "auth_$_" } @bases),
  (map { "auth_$_" } @constant_bases, "PRIMITIVE"),
];
my $hmacsha256 = [
  "auth_hmacsha256",
  (map { "auth_hmacsha256_$_" } @bases),
  (map { "auth_hmacsha256_$_" } @constant_bases),
];
my $hmacsha512 = [
  "auth_hmacsha512",
  (map { "auth_hmacsha512_$_" } @bases),
  (map { "auth_hmacsha512_$_" } @constant_bases),
];
my $hmacsha512256 = [
  "auth_hmacsha512256",
  (map { "auth_hmacsha512256_$_" } @bases),
  (map { "auth_hmacsha512256_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all => [ @$default, @$hmacsha256, @$hmacsha512, @$hmacsha512256 ],
  default => $default,
  hmacsha256 => $hmacsha256,
  hmacsha512 => $hmacsha512,
  hmacsha512256 => $hmacsha512256,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::auth - Secret key message authentication

=head1 SYNOPSIS

  use Crypt::Sodium::XS::auth ":default";

  my $key = auth_keygen;
  my $msg = "authenticate this message";

  my $tag = auth($msg, $key);
  die "message tampered with!" unless auth_verify($tag, $msg, $key);

  my $multipart = auth_init($key);
  $multipart->update("authenticate");
  $multipart->update(" this", " message");
  $tag = $multipart->final;
  die "message tampered with!" unless auth_verify($tag, $msg, $key);

=head1 DESCRIPTION

L<Crypt::Sodium::XS::auth> Computes an authentication tag for a message and a
secret key, and provides a way to verify that a given tag is valid for a given
message and a key.

The function computing the tag is deterministic: the same C<($message, $key)>
tuple will always produce the same output. However, even if the message is
public, knowing the key is required in order to be able to compute a valid tag.
Therefore, the key should remain confidential. The tag, however, can be public.

A typical use case is:

* Alice prepares a message, adds an authentication tag, sends it to Bob

* Alice doesn't store the message

* Later on, Bob sends the message and the authentication tag back to Alice

* Alice uses the authentication tag to verify that she created this message

L<Crypt::Sodium::XS::auth> does not encrypt the message. It only computes and
verifies an authentication tag.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<auth_E<lt>primitiveE<gt>_*> functions and constants for that primitive. A
C<:all> tag imports everything.

=head2 auth

=head2 auth_E<lt>primitiveE<gt>

  my $tag = auth($message, $key);

C<$message> is the message to authenticate. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$key> is the secret key with which to generate the authentication tag. It
must be L</auth_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the authentication tag. The tag is L</auth_BYTES> bytes.

=head2 auth_init

=head2 auth_E<lt>primitiveE<gt>_init

  my $multipart = auth_init($key, $flags);

C<$key> is the secret key used by the multipart object. It should be at least
L</auth_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the multipart protected memory
object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a multi-part auth object. This is
useful when authenticating a stream or large message in chunks, rather than in
one message. See L</MULTI-PART INTERFACE>.

B<Note>: The multipart interface may use arbitrary-size keys. This is not
recommended as it can be easily misused (e.g., accidentally using an empty
key). Avoid by always using keys of L</auth_KEYBYTES> bytes as returned by
L</auth_keygen>.

=head2 auth_keygen

=head2 auth_E<lt>primitiveE<gt>_keygen

  my $key = auth_keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a new secret key of L</auth_KEYBYTES>
bytes.

=head2 auth_verify

=head2 auth_E<lt>primitiveE<gt>_verify

  my $is_valid = auth_verify($tag, $message, $key);

C<$tag> is the previously generated authentication tag. It must be
L</auth_BYTES> bytes.

C<$message> is the message to authenticate.

C<$key> is the secret key used to generate the authentication tag. It must be
L</auth_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns true if C<$tag> is a valid tag for C<$message> and C<$key>, false
otherwise.

=head1 MULTI-PART INTERFACE

A multipart auth object is created by calling the L</auth_init> function. Data
to be authenticated is added by calling the L</update> method of that object as
many times as desired. An output tag is generated by calling its L</final>
method. Do not use the object after calling L</final>.

The multipart auth object is an opaque object which provides the following
methods:

=head2 clone

  my $multipart_copy = $multipart->clone;

Returns a cloned copy of the multipart auth object, duplicating its internal
state.

=head2 final

  my $tag = $multipart->final;

Returns a tag for C<$key> (from L</auth_init>) and all authenticated data (from
L</update>). The tag is L</auth_BYTES> bytes.

Once L</final> has been called, the multipart object must not be used further.

=head2 update

  $multipart->update(@messages);

Adds all given arguments (stringified) to authenticated data. Any argument may
be a L<Crypt::Sodium::XS::MemVault>.

=head1 CONSTANTS

=head2 auth_PRIMITIVE

  my $default_primitive = auth_PRIMITIVE();

Returns the name of the default primitive.

=head2 auth_BYTES

=head2 auth_E<lt>primitiveE<gt>_BYTES

  my $tag_size = auth_BYTES();

The size, in bytes, of an authentication tag.

=head2 auth_KEYBYTES

=head2 auth_E<lt>primitiveE<gt>_KEYBYTES

  my $key_size = auth_KEYBYTES();

The size, in bytes, of a secret key.

=head1 PRIMITIVES

=over 4

=item * hmachsa256

=item * hmacsha512

=item * hmacsha512256 (default)

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::auth>

=item L<https://doc.libsodium.org/secret-key_cryptography/secret-key_authentication>

=item L<https://doc.libsodium.org/advanced/hmac-sha2>

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
