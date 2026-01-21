package Crypt::Sodium::XS::kdf;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(
    BYTES_MAX
    BYTES_MIN
    CONTEXTBYTES
    KEYBYTES
    DERIVE_ID_CEILING
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
}

package Crypt::Sodium::XS::OO::kdf;
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

sub Crypt::Sodium::XS::kdf::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::kdf::primitives;

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

Crypt::Sodium::XS::kdf - Secret subkey derivation from a main secret key

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  my $kdf = Crypt::Sodium::XS->kdf;

  my $context = "see notes below about context strings";
  my $output_key_size = 32;
  my $master_key = $kdf->keygen;
  my $subkey_1 = $kdf->derive($master_key, 1, $output_key_size, $context);
  my $subkey_2 = $kdf->derive($master_key, 2, $output_key_size, $context);
  my $subkey_3 = $kdf->derive($master_key, 54321, $output_key_size, $context);

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

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>kdf> method.

  my $kdf = Crypt::Sodium::XS->kdf;
  my $kdf = Crypt::Sodium::XS->kdf(primitive => 'blake2b');

Returns a new kdf object.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::kdf>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $kdf->primitive;
  $kdf->primitive('blake2b');

Gets or sets the primitive used for all operations by this object. Must be one
of the primitives listed in L</PRIMITIVES>, including C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = $kdf->primitives;
  my @primitives = Crypt::Sodium::XS::kdf->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $kdf->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 derive

  my $subkey = $kdf->derive($key, $id, $subkey_size, $context, $flags);

C<$key> is the master key from which others should be derived. It must be
L</KEYBYTES> bytes. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$id> is an unsigned integer signifying the numeric identifier of the subkey
which is being derived. It must be less than L</kdf_DERIVE_ID_CEILING>. The
same C<$key>, C<$id>, C<$subkey_size>, and C<$context> will always derive the
same key.

C<$subkey_size> is the size, in bytes, of the subkey output. This can be used
to derive a key of the particular size needed for the primitive with which the
subkey will be used. It must be in the range of L</BYTES_MIN> to L</BYTES_MAX>,
inclusive.

C<$context> is optional. It is an arbitrary string which is at least
L</CONTEXTBYTES> bytes (see warning below). This can be used to create an
application-specific tag, such that using the same C<$key>, C<$id>, and
C<$subkey_size> can still derive a different subkey.

C<$flags> is optional. It is the flags used for the C<$subkey>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

B<WARNING>: C<$context> must be at least L</CONTEXTBYTES> bytes. If it is
longer than this, only the first L</CONTEXTBYTES> bytes will be used. As this
gives a limited range of use (application-specific strings might be likely to
have the same first 8 bytes), it is recommended to use an arbitrary-length
string as the input to a hash function (e.g.,
L<Crypt::Sodium::XS::generichash/generichash> or
L<Crypt::Sodium::XS::shorthash/shorthash>) and use the output hash as
C<$context>.

B<Note>: C<$id> is limited to one less than L</DERIVE_ID_CEILING>. This
artificial limitation is applied on all platforms to prevent accidental
derivation of duplicate keys due to handling of numeric values in perl --
because the author doesn't know of a better way. This should improve in the
future. In perl, it is possible to lose numeric precision above C<2 ** 53>
(when a number is stored and operated upon as NV; a double). This is always the
case on 32-bit systems, but can happen to numeric values on 64-bit systems as
well depending on the context of the perl code. Example from a 64-bit system
(if this limitation were not in place):

  my $kdf = Crypt::Sodium::XS->kdf;
  my $k = "\0" x $kdf->KEYBYTES; # null key
  my $x = 2 ** 53 - 2;
  $kdf->derive($k, $x++, 32)->to_base64->unlock for (1 .. 6);
  # output:
  # rHfr3QmtE_SSsGozwo9C1Ho24quHYMZqsu4Ax6KK_e0
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc <--- note that this is 2 ** 53
  # v4sP0CLKMBbKmxvpG4IHzZui-5cTCozjJu57GdNB3ac
  # Ual0mve2EEwqAh2Uqpa7dMUNyWslVb-kFWUIdnVrdcw <--- note again, 2 ** 53 + 2
  # AbYjao-tEhLyFzPvmmk1viGummBid5MrN3kczzFm1TE
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw <--- note again, 2 ** 53 + 4
  $x = 2 ** 53;
  $kdf->derive($k, $x++, 32)->to_base64->unlock for (1 .. 5);
  # output:
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc <--- 2 ** 53
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  $x += 2;  # adding 1 just repeats the above behavior
  $kdf->derive($k, $x++, 32)->to_base64->unlock for (1 .. 5);
  # Ual0mve2EEwqAh2Uqpa7dMUNyWslVb-kFWUIdnVrdcw <--- 2 ** 53 + 2
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw <--- 2 ** 53 + 4
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw

=head2 keygen

  my $key = $kdf->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a master key of L</KEYBYTES> bytes.

=head2 BYTES_MAX

  my $subkey_max_size = $kdf->BYTES_MAX;

Returns the maximum size, in bytes, of a generated subkey.

=head2 BYTES_MIN

  my $subkey_min_size = $kdf->BYTES_MIN;

Returns the minimum size, in bytes, of a generated subkey.

=head2 CONTEXTBYTES

  my $context_size = $kdf->CONTEXTBYTES;

Returns the size, in bytes, of a context string.

=head2 KEYBYTES

  my $main_key_size = $kdf->KEYBYTES;

Returns the size, in bytes, of a master key.

=head2 DERIVE_ID_CEILING

  die "cannot use this id" unless ($id < $kdf->DERIVE_ID_CEILING);

Returns one more than the maximum usable id for L</derive>.

B<Note>: This is specific to L<Crypt::Sodium::XS>; it is not a libsodium
constant.

=head1 PRIMITIVES

=over 4

=item * blake2b (default)

=back

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
which is being derived. It must be less than L</kdf_DERIVE_ID_CEILING> (see
note below). The same C<$key>, C<$id>, C<$subkey_size>, and C<$context> will
always derive the same key.

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

B<Note>: C<$id> is limited to one less than L</kdf_DERIVE_ID_CEILING>. This
limitation is applied on all platforms to prevent accidental derivation of
duplicate keys due to handling of numeric values in perl. In perl, it is
possible to lose numeric precision above C<2 ** 53> (when a number is stored
and operated upon as NV; a double). This is always the case on 32-bit systems,
but can happen to numeric values on 64-bit systems as well depending on the
context of the perl code. Example from a 64-bit system (if this limitation were
not in place):

  my $k = "\0" x kdf_KEYBYTES(); # null key
  my $x = 2 ** 53 - 2;
  kdf_derive($k, $x++, 32)->to_base64->unlock for (1 .. 6);
  # output:
  # rHfr3QmtE_SSsGozwo9C1Ho24quHYMZqsu4Ax6KK_e0
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc <--- note that this is 2 ** 53
  # v4sP0CLKMBbKmxvpG4IHzZui-5cTCozjJu57GdNB3ac
  # Ual0mve2EEwqAh2Uqpa7dMUNyWslVb-kFWUIdnVrdcw <--- note again, 2 ** 53 + 2
  # AbYjao-tEhLyFzPvmmk1viGummBid5MrN3kczzFm1TE
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw <--- note again, 2 ** 53 + 4
  $x = 2 ** 53;
  kdf_derive($k, $x++, 32)->to_base64->unlock for (1 .. 5);
  # output:
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc <--- 2 ** 53
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  # ixpuCXMoYQ15uBk_ZzFbHqH_qVQGywke-uBmutPPjcc
  $x += 2;  # adding 1 just repeats the above behavior
  kdf_derive($k, $x++, 32)->to_base64->unlock for (1 .. 5);
  # Ual0mve2EEwqAh2Uqpa7dMUNyWslVb-kFWUIdnVrdcw <--- 2 ** 53 + 2
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw <--- 2 ** 53 + 4
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw
  # rRVOLHdBIXVk6gWPHjCsjXGz-SERFUUne3_9TMtX2Vw

B<WARNING>: C<$context> must be at least L</kdf_CONTEXTBYTES> bytes. If it
is longer than this, only the first L</kdf_CONTEXTBYTES> bytes will be used. As
this gives a limited range of use (application-specific strings might be likely
to have the same first 8 bytes), it is recommended to use an arbitrary-length
string as the input to a hash function (e.g.,
L<Crypt::Sodium::XS::generichash/generichash> or
L<Crypt::Sodium::XS::shorthash/shorthash>) and use the output hash as
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

Returns the maximum size, in bytes, of a generated subkey.

=head2 kdf_BYTES_MIN

=head2 kdf_E<lt>primitiveE<gt>_BYTES_MIN

  my $subkey_min_size = kdf_BYTES_MIN();

Returns the minimum size, in bytes, of a generated subkey.

=head2 kdf_CONTEXTBYTES

=head2 kdf_E<lt>primitiveE<gt>_CONTEXTBYTES

  my $context_size = kdf_CONTEXTBYTES();

Returns the size, in bytes, of a context string.

=head2 kdf_KEYBYTES

=head2 kdf_E<lt>primitiveE<gt>_KEYBYTES

  my $main_key_size = kdf_KEYBYTES();

Returns the size, in bytes, of a master key.

=head2 kdf_DERIVE_ID_CEILING

  die "cannot use this id" unless ($id < kdf_DERIVE_ID_CEILING());

Returns one more than the maximum usable id for L</derive>.

B<Note>: This is specific to L<Crypt::Sodium::XS>; it is not a libsodium
constant.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

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
