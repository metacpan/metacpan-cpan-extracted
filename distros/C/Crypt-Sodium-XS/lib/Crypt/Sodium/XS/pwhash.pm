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
  my $key_length = 32;
  my $key = pwhash($passphrase, $salt, $key_length);

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

The more specific C<pwhash_scryptsalsa208sha256_*> API uses the more
conservative and widely deployed Scrypt function.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants as documented below. A separate import tag is provided for each of
the primitives listed in L</PRIMITIVES>. For example, C<:argon2i> imports
C<pwhash_argon2i_str>. You should use at least one import tag.

=head2 pwhash

  my $hash = pwhash($password, $salt, $hash_length, $opslimit, $memlimit);

C<$hash_length> specifies the desired output hash length. It is optional. If
omitted or the provided argument is false, the default of L</pwhash_STRBYTES>
will be used. If provided, it must be from L</pwhash_BYTES_MIN> to
L</pwhash_BYTES_MAX>, inclusive.

C<$opslimit> specifies the cpu-hardness of generating the hash. It is optional.
If omitted or the provided argument is false, the default of
L</pwhash_OPSLIMIT_INTERACTIVE> will be used. If provided, it must be from
L</pwhash_OPSLIMIT_MIN> to L</pwhash_OPSLIMIT_MAX>, inclusive.

C<$memlimit> specifies the memory-hardness of generating the hash. It is
optional. If omitted or the provided argument is false, the default of
L</pwhash_MEMLIMIT_INTERACTIVE> will be used. If provided, it must be from
L</pwhash_MEMLIMIT_MIN> to L</pwhash_MEMLIMIT_MAX>, inclusive.

=head2 pwhash_salt

  my $salt = pwhash_salt();

Generate a random salt of L</pwhash_SALTBYTES> length.

=head2 pwhash_str

  my $hash_string = pwhash_str($password, $opslimit, $memlimit);

=head2 pwhash_str_needs_rehash

  my $needs_rehash = pwhash_str_needs_rehash($string);
  my $needs_rehash = pwhash_str_needs_rehash($string, $opslimit);
  my $needs_rehash = pwhash_str_needs_rehash($string, $opslimit, $memlimit);

=head2 pwhash_verify

  my $is_valid = pwhash_verify($hash_string, $password);

=head1 CONSTANTS

=head2 pwhash_PRIMITIVE

  my $default_primitive = pwhash_PRIMITIVE();

=head2 pwhash_BYTES_MAX

  my $hash_max_length = pwhash_BYTES_MAX();

=head2 pwhash_BYTES_MIN

  my $hash_min_length = pwhash_BYTES_MAX();

=head2 pwhash_MEMLIMIT_INTERACTIVE

  my $memlimit = pwhash_MEMLIMIT_INTERACTIVE();

=head2 pwhash_MEMLIMIT_MAX

  my $memlimit = pwhash_MEMLIMIT_MAX();

=head2 pwhash_MEMLIMIT_MIN

  my $memlimit = pwhash_MEMLIMIT_MIN();

=head2 pwhash_MEMLIMIT_MODERATE

  my $memlimit = pwhash_MEMLIMIT_MODERATE();

=head2 pwhash_MEMLIMIT_SENSITIVE

  my $memlimit = pwhash_MEMLIMIT_SENSITIVE();

=head2 pwhash_OPSLIMIT_INTERACTIVE

  my $opslimit = pwhash_OPSLIMIT_INTERACTIVE();

=head2 pwhash_OPSLIMIT_MAX

  my $memlimit = pwhash_OPSLIMIT_MAX();

=head2 pwhash_OPSLIMIT_MIN

  my $memlimit = pwhash_OPSLIMIT_MIN();

=head2 pwhash_OPSLIMIT_MODERATE

  my $opslimit = pwhash_OPSLIMIT_MODERATE();

=head2 pwhash_OPSLIMIT_SENSITIVE

  my $opslimit = pwhash_OPSLIMIT_SENSITIVE();

=head2 pwhash_PASSWD_MAX

  my $hash_max_length = pwhash_PASSWD_MAX();

=head2 pwhash_PASSWD_MIN

  my $hash_min_length = pwhash_PASSWD_MIN();

=head2 pwhash_SALTBYTES

  my $salt_length = pwhash_SALTBYTES();

=head2 pwhash_STRBYTES

  my $hash_string_length = pwhash_STRBYTES();

=head2 pwhash_STRPREFIX

  my $hash_string_prefix = pwhash_STRPREFIX();

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<pwhash_E<lt>primitiveE<gt>>-prefixed couterparts (e.g., pwhash_argon2id,
pwhash_argon2i_STRBYTES).

argon2i and argon2id are version 1.3 of the primitive.

=over 4

=item * argon2i

=item * argon2id

=item * scryptsalsa208sha256

=back

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
