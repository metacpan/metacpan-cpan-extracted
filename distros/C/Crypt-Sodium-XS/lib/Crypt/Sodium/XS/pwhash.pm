package Crypt::Sodium::XS::pwhash;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  BYTES_MAX
  BYTES_MIN
  MEMLIMIT_INTERACTIVE
  MEMLIMIT_MAX
  MEMLIMIT_MIN
  MEMLIMIT_MODERATE
  MEMLIMIT_SENSITIVE
  OPSLIMIT_INTERACTIVE
  OPSLIMIT_MAX
  OPSLIMIT_MIN
  OPSLIMIT_MODERATE
  OPSLIMIT_SENSITIVE
  PASSWD_MAX
  PASSWD_MIN
  SALTBYTES
  STRBYTES
  STRPREFIX
);

my @bases = qw(
  salt
  str
  str_needs_rehash
  verify
);

my $default = [
  "pwhash",
  (map { "pwhash_$_" } @bases),
  (map { "pwhash_$_" } @constant_bases, "PRIMITIVE"),
];
my $argon2i = [
  "pwhash_argon2i",
  (map { "pwhash_argon2i_$_" } @bases),
  (map { "pwhash_argon2i_$_" } @constant_bases),
];
my $argon2id = [
  "pwhash_argon2id",
  (map { "pwhash_argon2id_$_" } @bases),
  (map { "pwhash_argon2id_$_" } @constant_bases),
];
my $scryptsalsa208sha256 = [
  "pwhash_scryptsalsa208sha256",
  (map { "pwhash_scryptsalsa208sha256_$_" } @bases),
  (map { "pwhash_scryptsalsa208sha256_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all => [ @$default, @$argon2i, @$argon2id, @$scryptsalsa208sha256, ],
  default => $default,
  argon2i => $argon2i,
  argon2id => $argon2id,
  scryptsalsa208sha256 => $scryptsalsa208sha256,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::pwhash - Password hashing and verification

=head1 SYNOPSIS

  use Crypt::Sodium::XS::pwhash ":default";

  my $passphrase = "this is a passphrase.";

  # key derivation
  my $salt = sodium_random_bytes($pwhash->SALTBYTES);
  my $key_size = 32;
  my $key = pwhash($passphrase, $salt, $key_size);

  # password storage
  my $pwhash_str = pwhash_str($passphrase);
  die "bad password" unless pwhash_verify($pwhash_str, $passphrase);
  if (pwhash_str_needs_rehash($pwhash_str)) {
    my $new_pwhash_str = pwhash_str($passphrase);
  }

=head1 DESCRIPTION

Secret keys used to encrypt or sign confidential data have to be chosen from a
very large keyspace.  However, passwords are usually short, human-generated
strings, making dictionary attacks practical.

L<Crypt::Sodium::XS::pwhash> functions derive a secret key of any size from a
password and a salt.

=over 4

The generated key has the size defined by the application, no matter what the
password length is.

The same password hashed with same parameters will always produce the same
output.

The same password hashed with different salts will produce different outputs.

The function deriving a key from a password and a salt is CPU intensive and
intentionally requires a fair amount of memory. Therefore, it mitigates
brute-force attacks by requiring a significant effort to verify each password.

=back

Common use cases:

=over 4

=item * Password storage

Or rather: storing what it takes to verify a password without having to store
the actual password.

=item * Deriving a secret key from a password

For example, for disk encryption. L<Crypt::Sodium::XS::pwhash>'s high-level
C<pwhash_*> API currently leverages the Argon2id function on all platforms
(when not using primitive-specific functions). This can change at any point in
time, but it is guaranteed that a given version of libsodium can verify all
hashes produced by all previous versions, from any platform. Applications don't
have to worry about backward compatibility.

=back

The C<scryptsalsa208sha256> primitive uses the more conservative and widely
deployed Scrypt function.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<pwhash_E<lt>primitiveE<gt>_*> functions and constants for that primitive.
A C<:all> tag imports everything.

=head2 pwhash

=head2 pwhash_E<lt>primitiveE<gt>

  my $hash = pwhash($password, $salt, $hash_size, $opslimit, $memlimit);

C<$password> is an arbitrary-length input password. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$salt> is an arbitrary string which must be L</pwhash_SALTBYTES> bytes. It
may be random and does not need to be kept secret.

C<$hash_size> is optional. It specifies the desired output hash size, in bytes.
It must be in the range of L</pwhash_BYTES_MIN> to L</pwhash_BYTES_MAX>,
inclusive. If it is omitted or numifies to zero (undef, 0, ""), the default of
L</pwhash_STRBYTES> will be used.

C<$opslimit> is optional. It specifies the cpu-hardness of generating the hash.
It must be in the range of L</pwhash_OPSLIMIT_MIN> to L</pwhash_OPSLIMIT_MAX>,
inclusive. If it is omitted or numifies to zero (undef, 0, ""), the default of
L</pwhash_OPSLIMIT_INTERACTIVE> will be used.

C<$memlimit> is optional. It specifies the memory-hardness of generating the hash.
It must be in the range of L</pwhash_MEMLIMIT_MIN> to L</pwhash_MEMLIMIT_MAX>,
inclusive. If it is omitted or numifies to zero (undef, 0, ""), the default of
L</pwhash_MEMLIMIT_INTERACTIVE> will be used.

Returns a L<Crypt::Sodium::XS::MemVault>: the output hash of C<$hash_size>
bytes.

=head2 pwhash_salt

  my $salt = pwhash_salt();

Returns a random salt of L</pwhash_SALTBYTES> bytes.

=head2 pwhash_str

  my $hash_string = pwhash_str($password, $opslimit, $memlimit);

C<$password> is an arbitrary-length input password. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$opslimit> is optional. It specifies the cpu-hardness of generating the hash.
It must be in the range of L</pwhash_OPSLIMIT_MIN> to L</pwhash_OPSLIMIT_MAX>,
inclusive. If it is omitted or numifies to zero (undef, 0, ""), the default of
L</pwhash_OPSLIMIT_INTERACTIVE> will be used.

C<$memlimit> is optional. It specifies the memory-hardness of generating the
hash.  It must be in the range of L</pwhash_MEMLIMIT_MIN> to
L</pwhash_MEMLIMIT_MAX>, inclusive. If it is omitted or numifies to zero
(undef, 0, ""), the default of L</pwhash_MEMLIMIT_INTERACTIVE> will be used.

Returns an ASCII encoded string into out, which includes:

=over 4

* the result of a memory-hard, CPU-intensive hash function applied to the
  password passwd of length passwdlen

* the automatically generated salt used for the previous computation

* the other parameters required to verify the password, including the algorithm
  identifier, its version, opslimit, and memlimit.

=back

=head2 pwhash_str_needs_rehash

  my $needs_rehash = pwhash_str_needs_rehash($string);
  my $needs_rehash = pwhash_str_needs_rehash($string, $opslimit);
  my $needs_rehash = pwhash_str_needs_rehash($string, $opslimit, $memlimit);

C<$hash_string> is a string returned by a previous call to L</str>.

C<$opslimit> is optional. It specifies the required cpu-hardness of generating
the hash. It must be in the range of L</pwhash_OPSLIMIT_MIN> to
L</pwhash_OPSLIMIT_MAX>, inclusive. If it is omitted or numifies to zero
(undef, 0, ""), the default of L</pwhash_OPSLIMIT_INTERACTIVE> will be used.

C<$memlimit> is optional. It specifies the required memory-hardness of
generating the hash. It must be in the range of L</pwhash_MEMLIMIT_MIN> to
L</pwhash_MEMLIMIT_MAX>, inclusive. If it is omitted or numifies to zero
(undef, 0, ""), the default of L</pwhash_MEMLIMIT_INTERACTIVE> will be used.

Returns false if C<$hash_str> is a valid password verification string (as
generated by L</pwhash_str>) and matches the parameters C<$opslimit>,
C<$memlimit>, and the current primitive, true otherwise.

=head2 pwhash_verify

  my $is_valid = pwhash_verify($hash_string, $password);

C<$hash_string> is a string returned by a previous call to L</str>.

C<$password> is an arbitrary-length input password. It may be a
L<Crypt::Sodium::XS::MemVault>.

Returns true if C<$hash_string> is a valid password verification string (as
generated by L</str>) for C<$password>, false otherwise.

=head1 CONSTANTS

=head2 pwhash_PRIMITIVE

  my $default_primitive = pwhash_PRIMITIVE();

Returns the name of the default primitive.

=head2 pwhash_BYTES_MAX

  my $hash_max_size = pwhash_BYTES_MAX();

Returns the maximum size, in bytes, of hash output.

=head2 pwhash_BYTES_MIN

  my $hash_min_size = pwhash_BYTES_MAX();

Returns the minimum size, in bytes, of hash output.

=head2 pwhash_MEMLIMIT_INTERACTIVE

=head2 pwhash_OPSLIMIT_INTERACTIVE

  my $memlimit = pwhash_MEMLIMIT_INTERACTIVE();
  my $opslimit = pwhash_OPSLIMIT_INTERACTIVE();

Returns baseline values for interactive online applications. This currently
requires 64 MiB of dedicated RAM.

=head2 pwhash_MEMLIMIT_MODERATE

=head2 pwhash_OPSLIMIT_MODERATE

  my $memlimit = pwhash_MEMLIMIT_MODERATE();
  my $opslimit = pwhash_OPSLIMIT_MODERATE();

Returns baseline settings slightly higher than interactive. This requires 256
MiB of dedicated RAM and takes about 0.7 seconds on a 2.8 GHz Core i7 CPU.

=head2 pwhash_MEMLIMIT_SENSITIVE

=head2 pwhash_OPSLIMIT_SENSITIVE

  my $memlimit = pwhash_MEMLIMIT_SENSITIVE();
  my $opslimit = pwhash_OPSLIMIT_SENSITIVE();

Returns baseline settings for highly-sensitive and non-interactive sessions.
With these parameters, deriving a key takes about 3.5 seconds on a 2.8 GHz Core
i7 CPU and requires 1024 MiB of dedicated RAM.

=head2 pwhash_MEMLIMIT_MAX

  my $memlimit = pwhash_MEMLIMIT_MAX();

Returns the maximum memlimit.

=head2 pwhash_MEMLIMIT_MIN

  my $memlimit = pwhash_MEMLIMIT_MIN();

Returns the minimum memlimit.

=head2 pwhash_OPSLIMIT_MAX

  my $memlimit = pwhash_OPSLIMIT_MAX();

Returns the maximum opslimit.

=head2 pwhash_OPSLIMIT_MIN

  my $memlimit = pwhash_OPSLIMIT_MIN();

Returns the minimum opslimit.

=head2 pwhash_PASSWD_MAX

  my $hash_max_size = pwhash_PASSWD_MAX();

Returns the maximum size, in bytes, of password input.

=head2 pwhash_PASSWD_MIN

  my $hash_min_size = pwhash_PASSWD_MIN();

Returns the minimum size, in bytes, of password input.

=head2 pwhash_SALTBYTES

  my $salt_size = pwhash_SALTBYTES();

Returns the size, in bytes, of a salt.

=head2 pwhash_STRBYTES

  my $hash_string_size = pwhash_STRBYTES();

Returns the size, in bytes, of a string returned by L</pwhash_str>.

=head2 pwhash_STRPREFIX

  my $hash_string_prefix = pwhash_STRPREFIX();

Returns the primitive-specific prefix of a string returned by L</str>.

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<pwhash_E<lt>primitiveE<gt>>-prefixed couterparts (e.g., pwhash_argon2id,
pwhash_argon2i_STRBYTES).

argon2i and argon2id are version 1.3 of the primitive.

=over 4

=item * argon2i

=item * argon2id (default)

=item * scryptsalsa208sha256

=back

=head1 GUIDELINES FOR CHOOSING OPSLIMIT AND MEMLIMIT

Start by determining how much memory the function can use. What will be the
highest number of processes evaluating the function simultaneously (ideally, no
more than 1 per CPU core)? How much physical memory is guaranteed to be
available?

Set memlimit to the amount of memory you want to reserve for password hashing.

Then set opslimit to 3 and measure the time it takes to hash a password.

If this is way too long for your application, reduce memlimit, but keep
opslimit set to 3.

If the function is so fast that you can afford it to be more computationally
intensive without any usability issues, then increase opslimit.

For online use (e.g. logging in on a website), a 1 second computation is likely
to be the acceptable maximum.

For interactive use (e.g. a desktop application), a 5 second pause after having
entered a password is acceptable if the password doesn’t need to be entered
more than once per session.

For non-interactive and infrequent use (e.g. restoring an encrypted backup), an
even slower computation can be an option.

However, the best defense against brute-force password cracking is to use
strong passwords.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::pwhash>

=item L<https://doc.libsodium.org/password_hashing>

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
