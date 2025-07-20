package Crypt::Sodium::XS::generichash;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  BYTES
  BYTES_MIN
  BYTES_MAX
  KEYBYTES
  KEYBYTES_MIN
  KEYBYTES_MAX
);

my @bases = qw(
  init
  keygen
);

my $default = [
  "generichash",
  (map { "generichash_$_" } @bases),
  (map { "generichash_$_" } @constant_bases, "PRIMITIVE"),
];
my $blake2b = [
  "generichash_blake2b",
  "generichash_blake2b_init_salt_personal",
  "generichash_blake2b_salt_personal",
  (map { "generichash_blake2b_$_" } @bases),
  (map { "generichash_blake2b_$_" } @constant_bases),
  "generichash_blake2b_PERSONALBYTES",
  "generichash_blake2b_SALTBYTES",
];

our %EXPORT_TAGS = (
  all => [ @$default, @$blake2b ],
  default => $default,
  blake2b => $blake2b,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::generichash - Cryptographic hashing

=head1 SYNOPSIS

  use Crypt::Sodium::XS::generichash ":default";

  my $msg = "hello, world!";
  my $hash = generichash($msg);

  my $output_len = 64;
  my $key = generichash_keygen;
  $hash = generichash($msg, $output_len, $key);

  my $multipart = generichash_init;
  $multipart->update($msg);
  $hash = $multipart->final;

=head1 DESCRIPTION

L<Crypt::Sodium::XS::generichash> computes a fixed-size fingerprint for an
arbitrary long message.

Sample use cases:

=over 4

=item * File integrity checking

=item * Creating unique identifiers to index arbitrary long data

=back

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<generichash_E<lt>primitiveE<gt>_*> functions and constants for that
primitive. A C<:all> tag imports everything.

=head2 generichash

  my $hash = generichash($message, $hash_size, $key);

C<$message> is the message to hash. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$hash_size> is optional. It is the desired size, in bytes,  of the hashed
output. If it is omitted or numifies to zero (undef, 0, ""), the default hash
size L</generichash_BYTES> will be used. It must be in the range of
L</generichash_BYTES_MIN> to L</generichash_BYTES_MAX>, inclusive.

C<$key> is optional. It must be L</generichash_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the same
message will always produce the same hash output.

Returns hash output of the requested size.

=head2 generichash_init

  my $multipart = generichash_init($hash_size, $key, $flags);

C<$hash_size> is optional. It is the desired size, in bytes, of the hashed
output. If it is omitted or numifies to zero (undef, 0, ""), the default hash
size L</generichash_BYTES> will be used. It must be in the range of
L</generichash_BYTES_MIN> to L</generichash_BYTES_MAX>, inclusive.

C<$key> is optional. It must be L</generichash_KEYBYTES> bytes. It may be a
L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the same
message will always produce the same hash output.

C<$flags> is optional. It is the flags used for the multipart protected memory
object. See L<Crypt::Sodium::XS::ProtMem>.

Returns an opaque protected memory object: a multipart hashing object. See
L</MULTI-PART INTERFACE>.

=head2 generichash_keygen

  my $key = generichash_keygen($key_size, $flags);

C<$key_size> is optional. It is the desired size, in bytes, of the generated
key. If it is omitted or numifies to zero (undef, 0, ""), the default key
size L</generichash_KEYBYTES> will be used. It must be in the range of
L</generichash_KEYBYTES_MIN> to L</generichash_KEYBYTES_MAX>, inclusive.

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a secret key of C<$key_size> bytes.

=head1 blake2b FUNCTIONS

L<Crypt::Sodium::XS::generichash> has the following functions available only in
their primitive-specific form.

B<Warning>: For these functions C<$salt> and C<$personal> must be at least
L</generichash_blake2b_SALTBYTES> and L</generichash_blake2b_PERSONALBYTES> in
bytes, respectively. If they are longer than the required size, only the
initial bytes of the required size will be used. If these values are not being
randomly chosen, it is recommended to use an arbitrary-length string as the
input to a hash function (e.g., L<Crypt::Sodium::XS::generichash/generichash>
or L<Crypt::Sodium::XS::shorthash/shorthash>) and use the hash output rather
than the strings.

=head2 generichash_blake2b_salt_personal

  my $hash = generichash_blake2b_salt_personal(
    $message,
    $salt,
    $personal,
    $hash_size,
    $key
  );

C<$salt> is an arbitrary string which is at least
L</generichash_blake2b_SALTBYTES> bytes (see warnings above).

C<$personal> as an arbitrary string which is at least
L</generichash_blake2b_PERSONALBYTES> bytes (see warnings above).

C<$hash_size> is optional. It is the desired size of the hashed output. If it
is omitted or numifies to zero (undef, 0, ""), the default hash size
L</generichash_blake2b_BYTES> will be used. It must be in the range of
L</generichash_BYTES_MIN> to L</generichash_BYTES_MAX>, inclusive.

C<$key> is optional. It must be L</generichash_blake2b_KEYBYTES> bytes. It may
be a L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the
same message will always produce the same hash output.

=head2 generichash_blake2b_init_salt_personal

  my $multipart = generichash_blake2b_init_salt_personal(
    $salt,
    $personal,
    $hash_size,
    $key
  );

C<$salt> as an arbitrary string which is at least
C<generichash_blake2b_SALTBYTES> bytes(see warnings above).

C<$personal> as an arbitrary string which is at least
C<generichash_blake2b_PERSONALBYTES> bytes (see warnings above).

C<$hash_size> is optional. It is the desired size of the hashed output. If it
is omitted or numifies to zero (undef, 0, ""), the default hash size
L</generichash_blake2b_BYTES> will be used. It must be in the range of
L</generichash_BYTES_MIN> to L</generichash_BYTES_MAX>, inclusive.

C<$key> is optional. It must be L</generichash_blake2b_KEYBYTES> bytes. It may
be a L<Crypt::Sodium::XS::MemVault>. Note that if a key is not provided, the
same message will always produce the same hash output.

Returns a multipart hashing object. See L</MULTI-PART INTERFACE>.

=head1 MULTI-PART INTERFACE

A multipart hashing object is created by calling the L</generichash_init>
function. Data to be hashed is added by calling the L</update> method of that
object as many times as desired. An output hash is generated by calling its
L</final> method. Do not use the object after calling L</final>.

The multipart hashing object is an opaque object which provides the following
methods:

=head2 clone

  my $multipart_copy = $multipart->clone;

Returns a cloned copy of the multipart hashing object, duplicating its internal
state.

=head2 final

  my $hash = $multipart->final;

Returns the final hash for all data added with L</update>. The output hash size
will be the original C<$hash_size> given to L</generichash_init>.

Once C<final> has been called, the hashing object must not be used further.

=head2 update

  $multipart->update(@messages);

Adds all given arguments (stringified) to hashed data. Any argument may be a
L<Crypt::Sodium::XS::MemVault>.

=head1 CONSTANTS

=head2 generichash_PRIMITIVE

  my $default_primitive = generichash_PRIMITIVE();

Returns the name of the default primitive.

=head2 generichash_BYTES

  my $hash_default_size = generichash_BYTES();

Returns the recommended minimum size, in bytes, of hash output. This size makes
it practically impossible for two messages to produce the same fingerprint.

=head2 generichash_BYTES_MIN

  my $hash_min_size = generichash_BYTES_MIN();

Returns the minimum size, in bytes, of hash output.

=head2 generichash_BYTES_MAX

  my $hash_max_size = generichash_BYTES_MAX();

Returns the maximum size, in bytes, of hash output.

=head2 generichash_KEYBYTES

  my $key_default_size = generichash_KEYBYTES();

Returns the recommended size, in bytes, of secret keys.

=head2 generichash_KEYBYTES_MIN

  my $key_min_size = generichash_KEYBYTES_MIN();

Returns the minimum size, in bytes, of secret keys.

=head2 generichash_KEYBYTES_MAX

  my $key_max_size = generichash_KEYBYTES_MAX();

Returns the maximum size, in bytes, of secret keys.

=head1 blake2b CONSTANTS

L<Crypt::Sodium::XS::generichash> has the following constants available only in
their primitive-specific form.

=head3 generichash_blake2b_PERSONALBYTES

The size, in bytes, of personalization strings.

=head3 generichash_blake2b_SALTBYTES

The size, in bytes, of salts.

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<generichash_E<lt>primitive<gt>>-prefixed counterparts (e.g.
generichash_blake2b, generichash_blake2b_BYTES).

=over 4

=item * blake2b (default)

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

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
