package Crypt::Sodium::XS::OO::auth;
use strict;
use warnings;

use Crypt::Sodium::XS::auth;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES => \&Crypt::Sodium::XS::auth::auth_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::auth::auth_KEYBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::auth::auth_PRIMITIVE,
    auth => \&Crypt::Sodium::XS::auth::auth,
    init => \&Crypt::Sodium::XS::auth::auth_init,
    keygen => \&Crypt::Sodium::XS::auth::auth_keygen,
    verify => \&Crypt::Sodium::XS::auth::auth_verify,
  },
  hmacsha256 => {
    BYTES => \&Crypt::Sodium::XS::auth::auth_hmacsha256_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::auth::auth_hmacsha256_KEYBYTES,
    PRIMITVE => sub { 'hmacsha256' },
    auth => \&Crypt::Sodium::XS::auth::auth_hmacsha256,
    init => \&Crypt::Sodium::XS::auth::auth_hmacsha256_init,
    keygen => \&Crypt::Sodium::XS::auth::auth_hmacsha256_keygen,
    verify => \&Crypt::Sodium::XS::auth::auth_hmacsha256_verify,
  },
  hmacsha512 => {
    BYTES => \&Crypt::Sodium::XS::auth::auth_hmacsha512_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::auth::auth_hmacsha512_KEYBYTES,
    PRIMITVE => sub { 'hmacsha512' },
    auth => \&Crypt::Sodium::XS::auth::auth_hmacsha512,
    init => \&Crypt::Sodium::XS::auth::auth_hmacsha512_init,
    keygen => \&Crypt::Sodium::XS::auth::auth_hmacsha512_keygen,
    verify => \&Crypt::Sodium::XS::auth::auth_hmacsha512_verify,
  },
  hmacsha512256 => {
    BYTES => \&Crypt::Sodium::XS::auth::auth_hmacsha512256_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::auth::auth_hmacsha512256_KEYBYTES,
    PRIMITVE => sub { 'hmacsha512256' },
    auth => \&Crypt::Sodium::XS::auth::auth_hmacsha512256,
    init => \&Crypt::Sodium::XS::auth::auth_hmacsha512256_init,
    keygen => \&Crypt::Sodium::XS::auth::auth_hmacsha512256_keygen,
    verify => \&Crypt::Sodium::XS::auth::auth_hmacsha512256_verify,
  },
);

sub primitives { keys %methods }

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES}; }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub auth { my $self = shift; goto $methods{$self->{primitive}}->{auth}; }
sub init { my $self = shift; goto $methods{$self->{primitive}}->{init}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub verify { my $self = shift; goto $methods{$self->{primitive}}->{verify}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::auth - Secret key message authentication

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  my $auth = Crypt::Sodium::XS->auth;

  my $key = $auth->keygen;
  my $msg = "authenticate this message";

  my $tag = $auth->auth($msg, $key);
  die "message tampered with!" unless $auth->verify($tag, $msg, $key);

  my $multipart = $auth->init($key);
  $multipart->update("authenticate");
  $multipart->update(" this", " message");
  $tag = $multipart->final;
  die "message tampered with!" unless $auth->verify($tag, $msg, $key);

=head1 DESCRIPTION

L<Crypt::Sodium::XS::OO::auth> computes an authentication tag for a message and
a secret key, and provides a way to verify that a given tag is valid for a
given message and a key.

The function computing the tag is deterministic: the same C<($message, $key)>
tuple will always produce the same output. However, even if the message is
public, knowing the key is required in order to be able to compute a valid tag.
Therefore, the key should remain confidential. The tag, however, can be public.

A typical use case is:

* Alice prepares a message, adds an authentication tag, sends it to Bob

* Alice doesn't store the message

* Later on, Bob sends the message and the authentication tag back to Alice

* Alice uses the authentication tag to verify that she created this message

L<Crypt::Sodium::XS::OO::auth> does not encrypt the message. It only computes
and verifies an authentication tag.

=head1 CONSTRUCTOR

=head2 new

  my $auth = Crypt::Sodium::XS::OO::auth->new(primitive => 'hmacsha256');
  my $auth = Crypt::Sodium::XS->auth;

Returns a new auth object for the given primitive. If not given, the default
primitive is C<default>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $auth->primitive;
  $auth->primitive('hmacsha256');

Gets or sets the primitive used for all operations by this object. Note this
can be C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = Crypt::Sodium::XS::OO::auth->primitives;
  my @primitives = $auth->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $auth->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 auth

  my $tag = $auth->auth($message, $key);

C<$message> is the message to authenticate. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$key> is the secret key with which to generate the authentication tag. It
must be L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns the authentication tag. The tag is L</BYTES> bytes.

=head2 init

  my $multipart = $auth->init($key, $flags);

C<$key> is the secret key used by the multipart object. It should be at least
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$flags> is optional. It is the flags used for the multipart protected memory
object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a multi-part auth object. This is
useful when authenticating a stream or large message in chunks, rather than in
one message. See L</MULTI-PART INTERFACE>.

B<Note>: The multipart interface may use arbitrary-size keys. This is not
recommended as it can be easily misused (e.g., accidentally using an empty
key). Avoid by always using keys of L</KEYBYTES> bytes as returned by
L</keygen>.

=head2 keygen

  my $key = $auth->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a new secret key of L</KEYBYTES>
bytes.

=head2 verify

  my $is_valid = $auth->verify($tag, $message, $key);

C<$tag> is the previously generated authentication tag. It must be L</BYTES>
bytes.

C<$message> is the message to authenticate.

C<$key> is the secret key used to generate the authentication tag. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

Returns true if C<$tag> is a valid tag for C<$message> and C<$key>, false
otherwise.

=head2 BYTES

  my $tag_size = $auth->BYTES;

The size, in bytes, of an authentication tag.

=head2 KEYBYTES

  my $key_size = $auth->KEYBYTES;

The size, in bytes, of a secret key.

=head1 MULTI-PART INTERFACE

A multipart auth object is created by calling the L</init> method. Data to be
authenticated is added by calling the L</update> method of that object as many
times as desired. An output tag is generated by calling its L</final> method.
Do not use the object after calling L</final>.

The multipart auth object is an opaque object which provides the following
methods:

=head2 clone

  my $multipart_copy = $multipart->clone;

Returns a cloned copy of the multipart auth object, duplicating its internal
state.

=head2 final

  my $tag = $multipart->final;

Returns a tag for C<$key> (from L</init>) and all authenticated data (from
L</update>). The tag is L</BYTES> bytes.

Once L</final> has been called, the multipart object must not be used further.

=head2 update

  $multipart->update(@messages);

Adds all given arguments (stringified) to authenticated data. Any argument may
be a L<Crypt::Sodium::XS::MemVault>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::auth>

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
