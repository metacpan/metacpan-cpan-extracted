package Crypt::Sodium::XS::kdf;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

my @constant_bases = qw(
  BYTES_MAX
  BYTES_MIN
  CONTEXTBYTES
  KEYBYTES
);
my @bases = qw(keygen derive);

my $default = [
  (map { "kdf_$_" } @bases),
  (map { "kdf_$_" } @constant_bases, "PRIMITIVE"),
];
my $blake2b = [
  (map { "kdf_blake2b_$_" } @bases),
  (map { "kdf_blake2b_$_" } @constant_bases),
];

our %EXPORT_TAGS = (
  all => [ @$default, @$blake2b, ],
  default => $default,
  blake2b => $blake2b,
);

our @EXPORT_OK = @{$EXPORT_TAGS{all}};

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::kdf - Secret subkey derivation from a main secret key

=head1 SYNOPSIS

  use Crypt::Sodium::XS::kdf ":default";

  my $context = "see notes below about context strings";
  my $output_key_size = 32;
  my $master_key = kdf_keygen();
  my $subkey_1 = kdf_derive($master_key, 1, $output_key_size, $context);
  my $subkey_2 = kdf_derive($master_key, 2, $output_key_size, $context);
  my $subkey_3 = kdf_derive($master_key, 54321, $output_key_size, $context);

=head1 DESCRIPTION

Multiple secret subkeys can be derived from a single high-entropy master key.
Given the master key and a numeric key identifier, a subkey can be
deterministically computed. However, given a subkey, an attacker cannot compute
the master key nor any other subkeys.

B<Note>: Secret keys used to encrypt or sign confidential data have to be
chosen from a very large keyspace. However, passwords are usually short,
human-generated strings, making dictionary attacks practical. If you are
intending to derive keys from a password, see L<Crypt::Sodium::XS::pwhash>
instead.

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<kdf_E<lt>primitiveE<gt>_*> functions and constants for that primitive. A
C<:all> tag imports everything.

=head2 kdf_derive

=head2 kdf_E<lt>primitiveE<gt>_derive

  my $subkey = kdf_derive($key, $id, $subkey_size, $context, $flags);

C<$key> is the master key from which others should be derived. It must be
L</kdf_KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$id> is an unsigned integer signifying the numeric identifier of the subkey
which is being derived. The same C<$key>, C<$id>, C<$subkey_size>, and
C<$context> will always derive the same key.

C<$subkey_size> is the size, in bytes, of the subkey output. This can be used
to derive a key of the particular size needed for the primitive with which the
subkey will be used. It must be in the range of L</kdf_BYTES_MIN> to
L</kdf_BYTES_MAX>, inclusive.

C<$context> is optional. It is an arbitrary string which is at least
L</kdf_CONTEXTBYTES> bytes (see warning below). This can be used to create an
application-specific tag, such that using the same C<$key>, C<$id>, and
C<$subkey_size> can still derive a different subkey.

C<$flags> is optional. It is the flags used for the C<$subkey>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

B<WARNING>: C<$context> must be at least L</kdf_CONTEXTBYTES> bytes. If it
is longer than this, only the first L</kdf_CONTEXTBYTES> bytes will be used. As
this gives a limited range of use (application-specific strings might be likely
to have the same first 8 bytes), it is recommended to use an arbitrary-length
string as the input to a hash function (e.g.,
L<Crypt::Sodium::XS::generichash/generichash> or
L<Crypt::Sodium::XS::shorthash/shorthash>) and use the output has as
C<$context>.

=head2 kdf_keygen

=head2 kdf_E<lt>primitiveE<gt>_keygen

  my $key = kdf_keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a master key of L</KEYBYTES> bytes.

=head1 CONSTANTS

=head2 kdf_PRIMITIVE

  my $default_primitive = kdf_PRIMITIVE();

Returns the name of the default primitive.

=head2 kdf_BYTES_MAX

=head2 kdf_E<lt>primitiveE<gt>_BYTES_MAX

  my $subkey_max_size = kdf_BYTES_MAX();

=head2 kdf_BYTES_MIN

=head2 kdf_E<lt>primitiveE<gt>_BYTES_MIN

  my $subkey_min_size = kdf_BYTES_MIN();

=head2 kdf_CONTEXTBYTES

=head2 kdf_E<lt>primitiveE<gt>_CONTEXTBYTES

  my $context_size = kdf_CONTEXTBYTES();

=head2 kdf_KEYBYTES

=head2 kdf_E<lt>primitiveE<gt>_KEYBYTES

  my $main_key_size = kdf_KEYBYTES();

=head1 PRIMITIVES

All constants (except _PRIMITIVE) and functions have
C<kdf_E<lt>primitiveE<gt>>-prefixed couterparts (e.g., kdf_blake2b_derive,
kdf_blake2b_BYTES_MIN).

=over 4

=item * blake2b (default)

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::kdf>

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
