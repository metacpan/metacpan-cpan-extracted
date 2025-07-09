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

L<Crypt::Sodium::XS::OO::generichash> computes a fixed-length fingerprint for
an arbitrary long message.

=head1 CONSTRUCTOR

=head2 new

  my $gh = Crypt::Sodium::XS::OO::generichash->new;
  my $gh = Crypt::Sodium::XS::OO::generichash->new(primitive => 'blake2b');
  my $gh = Crypt::Sodium::XS->generichash;

Returns a new generichash object for the given primitive. If not given, the
default primitive is C<default>.

=head1 METHODS

=head2 PRIMITIVE

  my $gh = Crypt::Sodium::XS::OO::generichash->new(primitive => 'default');
  my $default_primitive = $gh->PRIMITIVE;

=head2 BYTES

  my $hash_default_length = $gh->BYTES;

=head2 BYTES_MIN

  my $hash_min_length = $gh->BYTES_MIN;

=head2 BYTES_MAX

  my $hash_max_length = $gh->BYTES_MAX;

=head2 KEYBYTES

  my $key_default_length = $gh->KEYBYTES;

=head2 KEYBYTES_MIN

  my $key_min_length = $gh->KEYBYTES_MIN;

=head2 KEYBYTES_MAX

  my $key_max_length = $gh->KEYBYTES_MAX;

=head2 primitives

  my @primitives = $gh->primitives;

Returns a list of all supported primitive names (including 'default').

=head2 generichash

  my $hash = $gh->generichash($message, $hash_length, $key);
  my $hash = $gh->generichash($message, $hash_length);
  my $hash = $gh->generichash($message);
  my $hash = $gh->generichash($message, undef, $key);

C<$hash_length> is the desired length of the hashed output. It is optional. If
C<$hash_length> is omitted or numifies to zero (undef, 0, ""), the default hash
length (L</BYTES>) will be used.

C<$key> is optional.

=head2 init

  my $multipart = $gh->init($hash_length, $key);
  my $multipart = $gh->init($hash_length);
  my $multipart = $gh->init(undef, $key);

Returns a multipart hashing object. See L</MULTI-PART INTERFACE>.

C<$hash_length> is the desired length of the hashed output. It is optional. If
it is omitted or numifies to zero (undef, 0, ""), the default hash length
(L</BYTES>) will be used.

C<$key> is optional. If provided, it must be L</KEYBYTES> in length.

=head2 keygen

  my $key = $gh->keygen;
  my $key = $gh->keygen($key_length);

C<$key_length> is the desired length of the generated key. It is optional. If
it is omitted or numifies to zero (undef, 0, ""), the default key length
(L</KEYBYTES>) will be used. The length of C<$key_length>, if given, must be
from L</KEYBYTES_MIN> to L</KEYBYTES_MAX>, inclusive.

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

Note there is a difference to the sodium API. Finalizing the hash does not
require, nor accept, a new output length. The output hash length will be the
original C<$hash_length> given to L</init>.

Retruns the final hash for all data added with L</update>.

Once C<final> has been called, the hashing object must not be used further.

=head2 update

  $multipart->update($message);
  $multipart->update(@messages);

Adds all given arguments (stringified) to hashed data.

=head1 blake2b METHODS

The following methods are available only when explicitly using the C<blake2b>
primitive and fatal otherwise.

=head2 PERSONALBYTES

  my $personalbytes_len = $gh->PERSONALBYTES;

=head2 SALTBYTES

  my $salt_len = $gh->SALTBYTES;

=head2 salt_personal

  my $hash = $gh->salt_personal($message, $salt, $personal, $hash_length, $key);
  my $hash = $gh->salt_personal($message, $salt, $personal, $hash_length);
  my $hash = $gh->salt_personal($message, $salt, $personal);
  my $hash = $gh->salt_personal($message, $salt, $personal, undef, $key);

C<$salt> as an arbitrary string which is at least L<SALTBYTES> in length (see
warnings below).

C<$personal> as an arbitrary string which is at least L<PERSONALBYTES> in
length (see warnings below).

C<$hash_length> is the desired length of the hashed output. It is optional. If
C<$hash_length> is omitted or numifies to zero (undef, 0, ""), the default hash
length (L<BYTES>) will be used.

C<$key> is optional.

B<WARNING>: C<$salt> and C<$personal> must be at least L<SALTBYTES> and
L<PERSONALBYTES> in length, respectively. If they are longer than the required
length, only the required length of initial bytes will be used. If these values
are not being randomly chosen, it is recommended to use an arbitrary-length
string as the input to a hash function (e.g.,
L<Crypt::Sodium::XS::generichash/generichash> or
L<Crypt::Sodium::XS::shorthash/shorthash>) and use the hash output rather than
the strings.

=head2 init_salt_personal

  my $multipart = $gh->init_salt_personal($hash_length, $key);
  my $multipart = $gh->init_salt_personal($hash_length);
  my $multipart = $gh->init_salt_personal($hash_length, $key);

C<$hash_length> is the desired length of the hashed output. It is optional. If
it is omitted or numifies to zero (undef, 0, ""), the default hash length
(L<BYTES>) will be used.

C<$key> is optional. If provided, it must be L<KEYBYTES> in length.

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
