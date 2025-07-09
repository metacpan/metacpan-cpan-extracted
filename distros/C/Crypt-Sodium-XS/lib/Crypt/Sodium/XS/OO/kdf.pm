package Crypt::Sodium::XS::OO::kdf;
use strict;
use warnings;

use Crypt::Sodium::XS::kdf;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES_MAX => \&Crypt::Sodium::XS::kdf::kdf_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::kdf::kdf_BYTES_MIN,
    CONTEXTBYTES => \&Crypt::Sodium::XS::kdf::kdf_CONTEXTBYTES,
    KEYBYTES => \&Crypt::Sodium::XS::kdf::kdf_KEYBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::kdf::kdf_PRIMITIVE,
    derive => \&Crypt::Sodium::XS::kdf::kdf_derive,
    keygen => \&Crypt::Sodium::XS::kdf::kdf_keygen,
  },
  blake2b => {
    BYTES_MAX => \&Crypt::Sodium::XS::kdf::kdf_blake2b_BYTES_MAX,
    BYTES_MIN => \&Crypt::Sodium::XS::kdf::kdf_blake2b_BYTES_MIN,
    CONTEXTBYTES => \&Crypt::Sodium::XS::kdf::kdf_blake2b_CONTEXTBYTES,
    KEYBYTES => \&Crypt::Sodium::XS::kdf::kdf_blake2b_KEYBYTES,
    PRIMITIVE => sub { 'blake2b' },
    derive => \&Crypt::Sodium::XS::kdf::kdf_blake2b_derive,
    keygen => \&Crypt::Sodium::XS::kdf::kdf_blake2b_keygen,
  },
);

sub primitives { keys %methods }

sub BYTES_MAX { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MAX}; }
sub BYTES_MIN { my $self = shift; goto $methods{$self->{primitive}}->{BYTES_MIN}; }
sub CONTEXTBYTES { my $self = shift; goto $methods{$self->{primitive}}->{CONTEXTBYTES}; }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub derive { my $self = shift; goto $methods{$self->{primitive}}->{derive}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::kdf - Secret subkey derivation from a main secret key

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  my $kdf = Crypt::Sodium::XS->kdf;

  my $context = "see notes below about context strings";
  my $output_key_length = 32;
  my $master_key = $kdf->keygen;
  my $subkey_1 = $kdf->derive($master_key, 1, $output_key_length, $context);
  my $subkey_2 = $kdf->derive($master_key, 2, $output_key_length, $context);
  my $subkey_3 = $kdf->derive($master_key, 54321, $output_key_length, $context);

=head1 DESCRIPTION

NOTE: Secret keys used to encrypt or sign confidential data have to be chosen
from a very large keyspace. However, passwords are usually short,
human-generated strings, making dictionary attacks practical. If you are
intending to derive keys from a password, see L<Crypt::Sodium::XS::pwhash>
instead.

Multiple secret subkeys can be derived from a single high-entropy master key.
Given the master key and a numeric key identifier, a subkey can be
deterministically computed. However, given a subkey, an attacker cannot compute
the master key nor any other subkeys.

=head1 CONSTRUCTOR

=head2 new

  my $kdf = Crypt::Sodium::XS::OO::kdf->new;
  my $kdf = Crypt::Sodium::XS::OO::kdf->new(primitive => 'blake2b');
  my $kdf = Crypt::Sodium::XS->kdf;

Returns a new kdf object for the given primitive. If not given, the default
primitive is C<default>.

=head1 METHODS

=head2 PRIMITIVE

  my $kdf = Crypt::Sodium::XS::OO::kdf->new;
  my $default_primitive = $kdf->PRIMITIVE;

=head2 BYTES_MAX

  my $subkey_max_length = $kdf->BYTES_MAX;

=head2 BYTES_MIN

  my $subkey_min_length = $kdf->BYTES_MIN;

=head2 CONTEXTBYTES

  my $context_length = $kdf->CONTEXTBYTES;

=head2 KEYBYTES

  my $main_key_length = $kdf->KEYBYTES;

=head2 derive

  my $subkey = $kdf->derive($key, $id, $subkey_len, $context);

C<$key> is the master key from which others should be derived.

C<$id> is an unsigned integer signifying the numeric identifier of the subkey
which is being derived. The same C<$key>, C<$id>, C<$length>, and C<$context>
will always derive the same key.

C<$subkey_len> is the desired length of the subkey output. This can be used to
derive a key of the particular length needed for the primitive with which the
subkey will be used. It must be between L</BYTES_MIN> and L</BYTES_MAX>
(inclusive).

C<$context> as an arbitrary string which is at least L</CONTEXTBYTES> (see
warning below). This can be used to create an application-specific tag, such
that using the same C<$key>, C<$id>, and C<$subkey_len> can still derive a
different subkey.

B<WARNING>: C<$context> must be at least L</CONTEXTBYTES> in length. If it is
longer than this, only the first L</CONTEXTBYTES> bytes will be used. As this
gives a limited range of use (application-specific strings might be likely to
have the same first 8 bytes), it is recommended to use an arbitrary-length
string as the input to a hash function (e.g.,
L<Crypt::Sodium::XS::generichash/generichash> or
L<Crypt::Sodium::XS::shorthash/shorthash>) and use the output has as
C<$context>.

=head2 keygen

  my $key = $kdf->keygen;

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::kdf>

=item L<https://doc.libsodium.org/key_derivation>

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
