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
  my $key_length = 32;
  my $key = $pwhash->pwhash($passphrase, $salt, $key_length);

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

The more specific C<pwhash_scryptsalsa208sha256_*> API uses the more
conservative and widely deployed Scrypt function.

=head1 CONSTRUCTOR

=head2 new

  my $pwhash = Crypt::Sodium::XS::OO::pwhash->new;
  my $pwhash = Crypt::Sodium::XS::OO::pwhash->new(primitive => 'argon2id');
  my $pwhash = Crypt::Sodium::XS->pwhash;

Returns a new onetimeauth object for the given primitive. If not given, the
default primitive is C<default>.

=head1 METHODS

=head2 PRIMITIVE

  my $pwhash = Crypt::Sodium::XS::OO::pwhash->new;
  my $default_primitive = $pwhash->PRIMITIVE;

=head2 BYTES_MAX

  my $hash_max_length = $pwhash->BYTES_MAX;

=head2 BYTES_MIN

  my $hash_min_length = $pwhash->BYTES_MAX;

=head2 MEMLIMIT_INTERACTIVE

  my $memlimit = $pwhash->MEMLIMIT_INTERACTIVE;

=head2 MEMLIMIT_MAX

  my $memlimit = $pwhash->MEMLIMIT_MAX;

=head2 MEMLIMIT_MIN

  my $memlimit = $pwhash->MEMLIMIT_MIN;

=head2 MEMLIMIT_MODERATE

  my $memlimit = $pwhash->MEMLIMIT_MODERATE;

=head2 MEMLIMIT_SENSITIVE

  my $memlimit = $pwhash->MEMLIMIT_SENSITIVE;

=head2 OPSLIMIT_INTERACTIVE

  my $opslimit = $pwhash->OPSLIMIT_INTERACTIVE;

=head2 OPSLIMIT_MAX

  my $memlimit = $pwhash->OPSLIMIT_MAX;

=head2 OPSLIMIT_MIN

  my $memlimit = $pwhash->OPSLIMIT_MIN;

=head2 OPSLIMIT_MODERATE

  my $opslimit = $pwhash->OPSLIMIT_MODERATE;

=head2 OPSLIMIT_SENSITIVE

  my $opslimit = $pwhash->OPSLIMIT_SENSITIVE;

=head2 PASSWD_MAX

  my $hash_max_length = $pwhash->PASSWD_MAX;

=head2 PASSWD_MIN

  my $hash_min_length = $pwhash->PASSWD_MIN;

=head2 SALTBYTES

  my $salt_length = $pwhash->SALTBYTES;

=head2 STRBYTES

  my $hash_string_length = $pwhash->STRBYTES;

=head2 STRPREFIX

  my $hash_string_prefix = $pwhash->STRPREFIX;

=head2 primitives

  my @primitives = $pwhash->primitives;

Returns a list of all supported primitive names (including 'default').

=head2 pwhash

  my $hash
    = $pwhash->pwhash($password, $salt, $hash_length, $opslimit, $memlimit);

C<$hash_length> specifies the desired output hash length. It is optional. If
omitted or the provided argument is false, the default of L</STRBYTES> will be
used. If provided, it must be from L</BYTES_MIN> to L</BYTES_MAX>, inclusive.

C<$opslimit> specifies the cpu-hardness of generating the hash. It is optional.
If omitted or the provided argument is false, the default of
L</OPSLIMIT_INTERACTIVE> will be used. If provided, it must be from
L</OPSLIMIT_MIN> to L</OPSLIMIT_MAX>, inclusive.

C<$memlimit> specifies the memory-hardness of generating the hash. It is
optional. If omitted or the provided argument is false, the default of
L</MEMLIMIT_INTERACTIVE> will be used. If provided, it must be from
L</MEMLIMIT_MIN> to L</MEMLIMIT_MAX>, inclusive.

=head2 salt

  my $salt = $pwhash->salt;

Generate a random salt of L</SALTBYTES> length.

=head2 str

  my $hash_string = $pwhash->str($password, $opslimit, $memlimit);

=head2 str_needs_rehash

  my $needs_rehash = $pwhash->str_needs_rehash($string);
  my $needs_rehash = $pwhash->str_needs_rehash($string, $opslimit);
  my $needs_rehash = $pwhash->str_needs_rehash($string, $opslimit, $memlimit);

=head2 verify

  my $is_valid = $pwhash->verify($hash_string, $password);

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
