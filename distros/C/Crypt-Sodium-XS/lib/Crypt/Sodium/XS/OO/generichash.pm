package Crypt::Sodium::XS::OO::generichash;
use strict;
use warnings;

use Crypt::Sodium::XS::generichash;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES_MAX => \&Crypt::Sodium::XS::generichash::generichash_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::generichash::generichash_BYTES_MIN,
    KEYBYTES_MAX => \&Crypt::Sodium::XS::generichash::generichash_KEYBYTES_MAX,
    KEYBYTES_MIN => \&Crypt::Sodium::XS::generichash::generichash_KEYBYTES_MIN,
    PERSONALBYTES => sub { die "PERSONALBYTES not supported for default primitive" },
    PRIMITIVE => \&Crypt::Sodium::XS::generichash::generichash_PRIMITIVE,
    SALTBYTES => sub { die "SALTBYTES not supported for default primitive" },
    init => \&Crypt::Sodium::XS::generichash::generichash_init,
    init_salt_personal => sub { die "init_salt_personal not supported for default primitive" },
    keygen => \&Crypt::Sodium::XS::generichash::generichash_keygen,
    generichash => \&Crypt::Sodium::XS::generichash::generichash,
    salt_personal => sub { die "salt_personal not supported for default primitive" },
  },
  blake2b => {
    BYTES_MAX => \&Crypt::Sodium::XS::generichash::generichash_blake2b_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::generichash::generichash_blake2b_BYTES_MIN,
    KEYBYTES_MAX => \&Crypt::Sodium::XS::generichash::generichash_blake2b_KEYBYTES_MAX,
    KEYBYTES_MIN => \&Crypt::Sodium::XS::generichash::generichash_blake2b_KEYBYTES_MIN,
    PERSONALBYTES => \&Crypt::Sodium::XS::generichash::generichash_blake2b_PERSONALBYTES,
    PRIMITIVE => sub { 'blake2b' },
    SALTBYTES => \&Crypt::Sodium::XS::generichash::generichash_blake2b_SALTBYTES,
    init => \&Crypt::Sodium::XS::generichash::generichash_blake2b_init,
    init_salt_personal => \&Crypt::Sodium::XS::generichash::generichash_blake2b_init_salt_personal,
    keygen => \&Crypt::Sodium::XS::generichash::generichash_blake2b_keygen,
    generichash => \&Crypt::Sodium::XS::generichash::generichash_blake2b,
    salt_personal => \&Crypt::Sodium::XS::generichash::generichash_blake2b_salt_personal,
  },
);

sub primitives { keys %methods }

sub BYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MAX}; }
sub BYTES_MIN { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MIN}; }
sub KEYBYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES_MAX}; }
sub KEYBYTES_MIN { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES_MIN}; }
sub PERSONALBYTES { my $self = shift; goto $methods{$self->{primitive}}->{PERSONALBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub SALTBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SALTBYTES}; }
sub init { my $self = shift; goto $methods{$self->{primitive}}->{init}; }
sub init_salt_personal { my $self = shift; goto $methods{$self->{primitive}}->{init_salt_personal}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub generichash { my $self = shift; goto $methods{$self->{primitive}}->{generichash}; }
sub salt_personal { my $self = shift; goto $methods{$self->{primitive}}->{salt_personal}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::generichash - Cryptographic hashing

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  my $gh = Crypt::Sodium::XS->generichash;

  my $msg = "hello, world!";
  my $hash = $gh->generichash($msg);

  my $output_len = 64;
  my $key = $gh->keygen;
  $hash = $gh->generichash($msg, $output_len, $key);

  my $hasher = $gh->init;
  $hasher->update($msg);
  $hash = $hasher->final;

=head1 DESCRIPTION

L<Crypt::Sodium::XS::OO::generichash> computes a fixed-size fingerprint for an
arbitrary long message.

Sample use cases:

=over 4

=item * File integrity checking

=item * Creating unique identifiers to index arbitrary long data

=back

=head1 CONSTRUCTOR

=head2 new

  my $gh = Crypt::Sodium::XS::OO::generichash->new;
  my $gh = Crypt::Sodium::XS::OO::generichash->new(primitive => 'blake2b');
  my $gh = Crypt::Sodium::XS->generichash;

Returns a new generichash object for the given primitive. If not given, the
default primitive is C<default>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $gh->primitive;
  $gh->primitive('chacha20poly1305');

Gets or sets the primitive used for all operations by this object. Note this
can be C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = Crypt::Sodium::XS::generichash->primitives;
  my @primitives = $gh->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $gh->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 generichash

  my $hash = $gh->generichash($message, $hash_size, $key);
  my $hash = $gh->generichash($message, $hash_size);
  my $hash = $gh->generichash($message);
  my $hash = $gh->generichash($message, undef, $key);

C<$message> is the message to hash. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$hash_size> is optional. It is the desired size of the hashed output. If
it is omitted or numifies to zero (undef, 0, ""), the default hash size
L</BYTES> will be used. It must be in the range of L</BYTES_MIN> to
L</BYTES_MAX>, inclusive.

C<$key> is optional. It must be L</KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the same
message will always produce the same hash output.

Returns hash output of the requested length.

=head2 init

  my $multipart = $gh->init($hash_size, $key, $flags);

C<$hash_size> is optional. It is the desired length of the hashed output. If
it is omitted or numifies to zero (undef, 0, ""), the default hash length
L</BYTES> will be used. It must be in the range of L</BYTES_MIN> to
L</BYTES_MAX>, inclusive.

C<$key> is optional. It must be L</KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the same
message will always produce the same hash output.

C<$flags> is optional. It is the flags used for the multipart protected memory
object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a multipart hashing object. See
L</MULTI-PART INTERFACE>.

=head2 keygen

  my $key = $gh->keygen($key_size, $flags);

C<$key_size> is optional. It is the desired length of the generated key. If
it is omitted or numifies to zero (undef, 0, ""), the default key length
L</KEYBYTES> will be used. It must be in the range of L</KEYBYTES_MIN> to
L</KEYBYTES_MAX>, inclusive.

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of C<$key_size> bytes.

=head2 BYTES

  my $hash_default_size = $gh->BYTES;

Returns the recommended minimum size, in bytes, of hash output. This size makes
it practically impossible for two messages to produce the same fingerprint.

=head2 BYTES_MIN

  my $hash_min_size = $gh->BYTES_MIN;

Returns the minimum size, in bytes, of hash output.

=head2 BYTES_MAX

  my $hash_max_size = $gh->BYTES_MAX;

Returns the maximum size, in bytes, of hash output.

=head2 KEYBYTES

  my $key_default_size = $gh->KEYBYTES;

Returns the recommended size, in bytes, of secret keys.

=head2 KEYBYTES_MIN

  my $key_min_size = $gh->KEYBYTES_MIN;

Returns the minimum size, in bytes, of secret keys.

=head2 KEYBYTES_MAX

  my $key_max_size = $gh->KEYBYTES_MAX;

Returns the maximum size, in bytes, of secret keys.

=head1 MULTI-PART INTERFACE

A multipart hashing object is created by calling the L</init> method. Data to
be hashed is added by calling the L</update> method of that object as many
times as desired. An output hash is generated by calling its L</final> method.
Do not use the object after calling L</final>.

The multipart hashing object is an opaque object which provides the following
methods:

=head2 clone

  my $multipart_copy = $multipart->clone;

Returns a cloned copy of the multipart hashing object, duplicating its internal
state.

=head2 final

  my $hash = $multipart->final;

Returns the final hash for all data added with L</update>. The output hash size
will be the original C<$hash_size> given to L</init>.

Once C<final> has been called, the hashing object must not be used further.

=head2 update

  $multipart->update(@messages);

Adds all given arguments (stringified) to hashed data. Any argument may be a
L<Crypt::Sodium::XS::MemVault>.

=head1 blake2b METHODS

The following methods are available only when explicitly using the C<blake2b>
primitive and fatal otherwise.

B<Warning>: For these methods, C<$salt> and C<$personal> must be at least
L</SALTBYTES> and L</PERSONALBYTES> in bytes, respectively. If they are longer
than the required size, only the initial bytes of the required size will be
used. If these values are not being randomly chosen, it is recommended to use
an arbitrary-length string as the input to a hash function (e.g.,
L<Crypt::Sodium::XS::generichash/generichash> or
L<Crypt::Sodium::XS::shorthash/shorthash>) and use the hash output rather than
the strings.

=head2 PERSONALBYTES

  my $personalbytes_len = $gh->PERSONALBYTES;

The size, in bytes, of personalization strings.

=head2 SALTBYTES

  my $salt_len = $gh->SALTBYTES;

=head2 generichash_blake2b_SALTBYTES

=head2 salt_personal

  my $hash = $gh->salt_personal($message, $salt, $personal, $hash_size, $key);

C<$salt> is an arbitrary string which is at least L</SALTBYTES> bytes (see
warnings above).

C<$personal> as an arbitrary string which is at least L</PERSONALBYTES> bytes
(see warnings above).

C<$hash_size> is optional. It is the desired size of the hashed output. If it
is omitted or numifies to zero (undef, 0, ""), the default hash size L</BYTES>
will be used. It must be in the range of L</BYTES_MIN> to L</BYTES_MAX>,
inclusive.

C<$key> is optional. It must be L</KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the same
message will always produce the same hash output.

=head2 init_salt_personal

  my $multipart = $gh->init_salt_personal($salt, $personal, $hash_size, $key);

C<$salt> as an arbitrary string which is at least L</SALTBYTES> bytes (see
warnings above).

C<$personal> as an arbitrary string which is at least L</PERSONALBYTES> bytes
(see warnings above).

C<$hash_size> is optional. It is the desired size of the hashed output. If it
is omitted or numifies to zero (undef, 0, ""), the default hash size L</BYTES>
will be used. It must be in the range of L</BYTES_MIN> to L</BYTES_MAX>,
inclusive.

C<$key> is optional. It must be L</KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the same
message will always produce the same hash output.

Returns a multipart hashing object. See L</MULTI-PART INTERFACE>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::generichash>

=item L<https://doc.libsodium.org/hashing/generic_hashing>

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
