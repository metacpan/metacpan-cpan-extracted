package Crypt::Sodium::XS::OO::pwhash;
use strict;
use warnings;

use Crypt::Sodium::XS::pwhash;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_BYTES_MIN,
    MEMLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_MEMLIMIT_INTERACTIVE,
    MEMLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_MEMLIMIT_MIN,
    MEMLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_MEMLIMIT_MAX,
    MEMLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_MEMLIMIT_MODERATE,
    MEMLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_MEMLIMIT_SENSITIVE,
    OPSLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_OPSLIMIT_INTERACTIVE,
    OPSLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_OPSLIMIT_MIN,
    OPSLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_OPSLIMIT_MAX,
    OPSLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_OPSLIMIT_MODERATE,
    OPSLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_OPSLIMIT_SENSITIVE,
    PASSWD_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_PASSWD_MAX,
    PASSWD_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_PASSWD_MIN,
    PRIMITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_PRIMITIVE,
    SALTBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_SALTBYTES,
    STRBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_STRBYTES,
    STRPREFIX => \&Crypt::Sodium::XS::pwhash::pwhash_STRPREFIX,
    pwhash => \&Crypt::Sodium::XS::pwhash::pwhash,
    salt => \&Crypt::Sodium::XS::pwhash::pwhash_salt,
    str => \&Crypt::Sodium::XS::pwhash::pwhash_str,
    str_needs_rehash => \&Crypt::Sodium::XS::pwhash::pwhash_str_needs_rehash,
    verify => \&Crypt::Sodium::XS::pwhash::pwhash_verify,
  },
  argon2i => {
    BYTES_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_BYTES_MIN,
    MEMLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_MEMLIMIT_INTERACTIVE,
    MEMLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_MEMLIMIT_MIN,
    MEMLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_MEMLIMIT_MAX,
    MEMLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_MEMLIMIT_MODERATE,
    MEMLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_MEMLIMIT_SENSITIVE,
    OPSLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_OPSLIMIT_INTERACTIVE,
    OPSLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_OPSLIMIT_MODERATE,
    OPSLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_OPSLIMIT_MIN,
    OPSLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_OPSLIMIT_MAX,
    OPSLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_OPSLIMIT_SENSITIVE,
    PASSWD_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_PASSWD_MAX,
    PASSWD_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_PASSWD_MIN,
    PRIMITIVE => sub { 'argon2i' },
    SALTBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_SALTBYTES,
    STRBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_STRBYTES,
    STRPREFIX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_STRPREFIX,
    pwhash => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i,
    salt => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_salt,
    str => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_str,
    str_needs_rehash => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_str_needs_rehash,
    verify => \&Crypt::Sodium::XS::pwhash::pwhash_argon2i_verify,
  },
  argon2id => {
    BYTES_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_BYTES_MIN,
    MEMLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_MEMLIMIT_INTERACTIVE,
    MEMLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_MEMLIMIT_MIN,
    MEMLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_MEMLIMIT_MAX,
    MEMLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_MEMLIMIT_MODERATE,
    MEMLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_MEMLIMIT_SENSITIVE,
    OPSLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_OPSLIMIT_INTERACTIVE,
    OPSLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_OPSLIMIT_MIN,
    OPSLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_OPSLIMIT_MAX,
    OPSLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_OPSLIMIT_MODERATE,
    OPSLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_OPSLIMIT_SENSITIVE,
    PASSWD_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_PASSWD_MAX,
    PASSWD_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_PASSWD_MIN,
    PRIMITIVE => sub { 'argon2id' },
    SALTBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_SALTBYTES,
    STRBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_STRBYTES,
    STRPREFIX => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_STRPREFIX,
    pwhash => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id,
    salt => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_salt,
    str => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_str,
    str_needs_rehash => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_str_needs_rehash,
    verify => \&Crypt::Sodium::XS::pwhash::pwhash_argon2id_verify,
  },
  scryptsalsa208sha256 => {
    BYTES_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_BYTES_MIN,
    MEMLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE,
    MEMLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_MEMLIMIT_MIN,
    MEMLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_MEMLIMIT_MAX,
    MEMLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_MEMLIMIT_MODERATE,
    MEMLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE,
    OPSLIMIT_INTERACTIVE => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE,
    OPSLIMIT_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_OPSLIMIT_MIN,
    OPSLIMIT_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_OPSLIMIT_MAX,
    OPSLIMIT_MODERATE => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_OPSLIMIT_MODERATE,
    OPSLIMIT_SENSITIVE => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE,
    PASSWD_MAX => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_PASSWD_MAX,
    PASSWD_MIN => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_PASSWD_MIN,
    PRIMITIVE => sub { 'scryptsalsa208sha256' },
    SALTBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_SALTBYTES,
    STRBYTES => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_STRBYTES,
    STRPREFIX => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_STRPREFIX,
    pwhash => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256,
    salt => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_salt,
    str => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_str,
    str_needs_rehash => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_str_needs_rehash,
    verify => \&Crypt::Sodium::XS::pwhash::pwhash_scryptsalsa208sha256_verify,
  },
);

sub primitives { keys %methods }

sub BYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MAX}; }
sub BYTES_MIN { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MIN}; }
sub MEMLIMIT_INTERACTIVE { my $self = shift; goto $methods{$self->{primitive}}->{MEMLIMIT_INTERACTIVE}; }
sub MEMLIMIT_MAX { my $self = shift; goto $methods{$self->{primitive}}->{MEMLIMIT_MAX}; }
sub MEMLIMIT_MIN { my $self = shift; goto $methods{$self->{primitive}}->{MEMLIMIT_MIN}; }
sub MEMLIMIT_MODERATE { my $self = shift; goto $methods{$self->{primitive}}->{MEMLIMIT_MODERATE}; }
sub MEMLIMIT_SENSITIVE { my $self = shift; goto $methods{$self->{primitive}}->{MEMLIMIT_SENSITIVE}; }
sub OPSLIMIT_INTERACTIVE { my $self = shift; goto $methods{$self->{primitive}}->{OPSLIMIT_INTERACTIVE}; }
sub OPSLIMIT_MAX { my $self = shift; goto $methods{$self->{primitive}}->{OPSLIMIT_MAX}; }
sub OPSLIMIT_MIN { my $self = shift; goto $methods{$self->{primitive}}->{OPSLIMIT_MIN}; }
sub OPSLIMIT_MODERATE { my $self = shift; goto $methods{$self->{primitive}}->{OPSLIMIT_MODERATE}; }
sub OPSLIMIT_SENSITIVE { my $self = shift; goto $methods{$self->{primitive}}->{OPSLIMIT_SENSITIVE}; }
sub PASSWD_MAX { my $self = shift; goto $methods{$self->{primitive}}->{PASSWD_MAX}; }
sub PASSWD_MIN { my $self = shift; goto $methods{$self->{primitive}}->{PASSWD_MIN}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub SALTBYTES { my $self = shift; goto $methods{$self->{primitive}}->{SALTBYTES}; }
sub STRBYTES { my $self = shift; goto $methods{$self->{primitive}}->{STRBYTES}; }
sub STRPREFIX { my $self = shift; goto $methods{$self->{primitive}}->{STRPREFIX}; }
sub pwhash { my $self = shift; goto $methods{$self->{primitive}}->{pwhash}; }
sub salt { my $self = shift; goto $methods{$self->{primitive}}->{salt}; }
sub str { my $self = shift; goto $methods{$self->{primitive}}->{str}; }
sub str_needs_rehash { my $self = shift; goto $methods{$self->{primitive}}->{str_needs_rehash}; }
sub verify { my $self = shift; goto $methods{$self->{primitive}}->{verify}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::pwhash - Password hashing and verification

=head1 SYNOPSIS

  use Crypt::Sodium::XS;
  use Crypt::Sodium::XS::Util "sodium_random_bytes";

  my $pwhash = Crypt::Sodium::XS->pwhash;

  my $passphrase = "this is a passphrase.";

  # key derivation
  my $salt = sodium_random_bytes($pwhash->SALTBYTES);
  my $key_size = 32;
  my $key = $pwhash->pwhash($passphrase, $salt, $key_size);

  # password storage
  my $pwhash_str = $pwhash->str($passphrase);
  die "bad password" unless $pwhash->verify($pwhash_str, $passphrase);
  if ($pwhash->str_needs_rehash($pwhash_str)) {
    my $new_pwhash_str = $pwhash->str($passphrase);
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

=head1 CONSTRUCTOR

=head2 new

  my $pwhash = Crypt::Sodium::XS::OO::pwhash->new(primitive => 'argon2id');
  my $pwhash = Crypt::Sodium::XS->pwhash;

Returns a new onetimeauth object for the given primitive. If not given, the
default primitive is C<default>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $pwhash->primitive;
  $pwhash->primitive('poly1305');

Gets or sets the primitive used for all operations by this object. Note this
can be C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = Crypt::Sodium::XS::OO::pwhash->primitives;
  my @primitives = $pwhash->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $default_primitive = $pwhash->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 pwhash

  my $hash
    = $pwhash->pwhash($password, $salt, $hash_size, $opslimit, $memlimit);

C<$password> is an arbitrary-length input password. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$salt> is an arbitrary string which must be L</SALTBYTES> bytes. It may be
random and does not need to be kept secret.

C<$hash_size> is optional. It specifies the desired output hash size, in bytes.
It must be in the range of L</BYTES_MIN> to L</BYTES_MAX>, inclusive. If it is
omitted or numifies to zero (undef, 0, ""), the default of L</pwhash_STRBYTES>
will be used.

C<$opslimit> is optional. It specifies the cpu-hardness of generating the hash.
It must be in the range of L</OPSLIMIT_MIN> to L</OPSLIMIT_MAX>, inclusive. If
it is omitted or numifies to zero (undef, 0, ""), the default of
L</OPSLIMIT_INTERACTIVE> will be used.

C<$memlimit> is optional. It specifies the memory-hardness of generating the hash.
It must be in the range of L</MEMLIMIT_MIN> to L</MEMLIMIT_MAX>, inclusive. If
it is omitted or numifies to zero (undef, 0, ""), the default of
L</MEMLIMIT_INTERACTIVE> will be used.

Returns the output hash of C<$hash_size> bytes.

=head2 salt

  my $salt = $pwhash->salt;

Returns a random salt of L</SALTBYTES> bytes.

=head2 str

  my $hash_string = $pwhash->str($password, $opslimit, $memlimit);

C<$password> is an arbitrary-length input password. It may be a
L<Crypt::Sodium::XS::MemVault>.

C<$opslimit> is optional. It specifies the cpu-hardness of generating the hash.
It must be in the range of L</OPSLIMIT_MIN> to L</OPSLIMIT_MAX>, inclusive. If
it is omitted or numifies to zero (undef, 0, ""), the default of
L</OPSLIMIT_INTERACTIVE> will be used.

C<$memlimit> is optional. It specifies the memory-hardness of generating the hash.
It must be in the range of L</MEMLIMIT_MIN> to L</MEMLIMIT_MAX>, inclusive. If
it is omitted or numifies to zero (undef, 0, ""), the default of
L</MEMLIMIT_INTERACTIVE> will be used.

Returns an ASCII encoded string into out, which includes:

=over 4

* the result of a memory-hard, CPU-intensive hash function applied to the
  password passwd of length passwdlen

* the automatically generated salt used for the previous computation

* the other parameters required to verify the password, including the algorithm
  identifier, its version, opslimit, and memlimit.

=back

=head2 str_needs_rehash

  my $needs_rehash
    = $pwhash->str_needs_rehash($hash_string, $opslimit, $memlimit);

C<$hash_string> is a string returned by a previous call to L</str>.

C<$opslimit> is optional. It specifies the required cpu-hardness of generating
the hash. It must be in the range of L</OPSLIMIT_MIN> to L</OPSLIMIT_MAX>,
inclusive. If it is omitted or numifies to zero (undef, 0, ""), the default of
L</OPSLIMIT_INTERACTIVE> will be used.

C<$memlimit> is optional. It specifies the required memory-hardness of
generating the hash. It must be in the range of L</MEMLIMIT_MIN> to
L</MEMLIMIT_MAX>, inclusive. If it is omitted or numifies to zero (undef, 0,
""), the default of L</MEMLIMIT_INTERACTIVE> will be used.

Returns false if C<$hash_str> is a valid password verification string (as
generated by L</str>) and matches the parameters C<$opslimit>, C<$memlimit>,
and the current primitive, true otherwise.

=head2 verify

  my $is_valid = $pwhash->verify($hash_string, $password);

C<$hash_string> is a string returned by a previous call to L</str>.

C<$password> is an arbitrary-length input password. It may be a
L<Crypt::Sodium::XS::MemVault>.

Returns true if C<$hash_string> is a valid password verification string (as
generated by L</str>) for C<$password>, false otherwise.

=head2 BYTES_MAX

  my $hash_max_size = $pwhash->BYTES_MAX;

Returns the maximum size, in bytes, of hash output.

=head2 BYTES_MIN

  my $hash_min_size = $pwhash->BYTES_MAX;

Returns the minimum size, in bytes, of hash output.

=head2 MEMLIMIT_INTERACTIVE

=head2 OPSLIMIT_INTERACTIVE

  my $memlimit = $pwhash->MEMLIMIT_INTERACTIVE;
  my $opslimit = $pwhash->OPSLIMIT_INTERACTIVE;

Returns baseline values for interactive online applications. This currently
requires 64 MiB of dedicated RAM.

=head2 MEMLIMIT_MODERATE

=head2 OPSLIMIT_MODERATE

  my $memlimit = $pwhash->MEMLIMIT_MODERATE;
  my $opslimit = $pwhash->OPSLIMIT_MODERATE;

Returns baseline settings slightly higher than interactive. This requires 256
MiB of dedicated RAM and takes about 0.7 seconds on a 2.8 GHz Core i7 CPU.

=head2 MEMLIMIT_SENSITIVE

=head2 OPSLIMIT_SENSITIVE

  my $memlimit = $pwhash->MEMLIMIT_SENSITIVE;
  my $opslimit = $pwhash->OPSLIMIT_SENSITIVE;

Returns baseline settings for highly-sensitive and non-interactive sessions.
With these parameters, deriving a key takes about 3.5 seconds on a 2.8 GHz Core
i7 CPU and requires 1024 MiB of dedicated RAM.

=head2 MEMLIMIT_MAX

  my $memlimit = $pwhash->MEMLIMIT_MAX;

Returns the maximum memlimit.

=head2 MEMLIMIT_MIN

  my $memlimit = $pwhash->MEMLIMIT_MIN;

Returns the minimum memlimit.

=head2 OPSLIMIT_MAX

  my $memlimit = $pwhash->OPSLIMIT_MAX;

Returns the maximum opslimit.

=head2 OPSLIMIT_MIN

  my $memlimit = $pwhash->OPSLIMIT_MIN;

Returns the minimum opslimit.

=head2 PASSWD_MAX

  my $hash_max_size = $pwhash->PASSWD_MAX;

Returns the maximum size, in bytes, of password input.

=head2 PASSWD_MIN

  my $hash_min_size = $pwhash->PASSWD_MIN;

Returns the minimum size, in bytes, of password input.

=head2 SALTBYTES

  my $salt_size = $pwhash->SALTBYTES;

Returns the size, in bytes, of a salt.

=head2 STRBYTES

  my $hash_string_size = $pwhash->STRBYTES;

Returns the size, in bytes, of a string returned by L</str>.

=head2 STRPREFIX

  my $hash_string_prefix = $pwhash->STRPREFIX;

Returns the primitive-specific prefix of a string returned by L</str>.

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

=item L<Crypt::Sodium::XS::pwhash>

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
