package Crypt::Sodium::XS::shorthash;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

{
  my @constant_bases = qw(
    BYTES
    KEYBYTES
  );

  my @bases = qw(
    keygen
  );

  my $default = [
    "shorthash",
    (map { "shorthash_$_" } @bases),
    (map { "shorthash_$_" } @constant_bases, "PRIMITIVE"),
  ];
  my $siphash24 = [
    "shorthash_siphash24",
    (map { "shorthash_siphash24_$_" } @bases),
    (map { "shorthash_siphash24_$_" } @constant_bases),
  ];
  my $siphashx24 = [
    "shorthash_siphashx24",
    (map { "shorthash_siphashx24_$_" } @bases),
    (map { "shorthash_siphashx24_$_" } @constant_bases),
  ];

  our %EXPORT_TAGS = (
    all => [ @$default, @$siphash24, @$siphashx24 ],
    default => $default,
    siphash24 => $siphash24,
    siphashx24 => $siphashx24,
  );

  our @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

package Crypt::Sodium::XS::OO::shorthash;
use parent 'Crypt::Sodium::XS::OO::Base';

my %methods = (
  default => {
    BYTES => \&Crypt::Sodium::XS::shorthash::shorthash_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::shorthash::shorthash_KEYBYTES,
    PRIMITIVE => \&Crypt::Sodium::XS::shorthash::shorthash_PRIMITIVE,
    keygen => \&Crypt::Sodium::XS::shorthash::shorthash_keygen,
    shorthash => \&Crypt::Sodium::XS::shorthash::shorthash,
  },
  siphash24 => {
    BYTES => \&Crypt::Sodium::XS::shorthash::shorthash_siphash24_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::shorthash::shorthash_siphash24_KEYBYTES,
    PRIMITIVE => sub { 'siphash24' },
    keygen => \&Crypt::Sodium::XS::shorthash::shorthash_siphash24_keygen,
    shorthash => \&Crypt::Sodium::XS::shorthash::shorthash_siphash24,
  },
  siphashx24 => {
    BYTES => \&Crypt::Sodium::XS::shorthash::shorthash_siphashx24_BYTES,
    KEYBYTES => \&Crypt::Sodium::XS::shorthash::shorthash_siphashx24_KEYBYTES,
    PRIMITIVE => sub { 'siphashx24' },
    keygen => \&Crypt::Sodium::XS::shorthash::shorthash_siphashx24_keygen,
    shorthash => \&Crypt::Sodium::XS::shorthash::shorthash_siphashx24,
  },
);

sub Crypt::Sodium::XS::shorthash::primitives { keys %methods }
*primitives = \&Crypt::Sodium::XS::shorthash::primitives;

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES}; }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub shorthash { my $self = shift; goto $methods{$self->{primitive}}->{shorthash}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::shorthash - Short-input hashing

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  my $shorthash = Crypt::Sodium::XS->shorthash;

  my $key = $shorthash->keygen;
  my $msg = "short input";

  my $hash = $shorthash->shorthash($msg, $key);

=head1 DESCRIPTION

L<Crypt::Sodium::XS::shorthash> outputs short but unpredictable (without
knowing the secret key) values suitable for picking a list in a hash table for
a given key. This function is optimized for short inputs.

The output of this function is only 64 bits. Therefore, it should not be
considered collision-resistant.

Use cases:

=over 4

=item * Hash tables

=item * Probabilistic data structures such as Bloom filters

=item * Integrity checking in interactive protocols

=back

=head1 CONSTRUCTOR

The constructor is called with the C<Crypt::Sodium::XS-E<gt>shorthash> method.

  my $shorthash = Crypt::Sodium::XS->shorthash;
  my $shorthash = Crypt::Sodium::XS->shorthash(primitive => 'siphash24');

Returns a new secretstream object.

Implementation detail: the returned object is blessed into
C<Crypt::Sodium::XS::OO::shorthash>.

=head1 ATTRIBUTES

=head2 primitive

  my $primitive = $shorthash->primitive;
  $shorthash->primitive('poly1305');

Gets or sets the primitive used for all operations by this object. It must be
one of the primitives listed in L</PRIMITIVES>, including C<default>.

=head1 METHODS

=head2 primitives

  my @primitives = $shorthash->primitives;
  my @primitives = Crypt::Sodium::XS::shorthash->primitives;

Returns a list of all supported primitive names, including C<default>.

Can be called as a class method.

=head2 PRIMITIVE

  my $primitive = $shorthash->PRIMITIVE;

Returns the primitive used for all operations by this object. Note this will
never be C<default> but would instead be the primitive it represents.

=head2 keygen

  my $key = $shorthash->keygen($flags);

C<$flags> is optional. It is the flags used for the C<$key>
L<Crypt::Sodium::XS::MemVault>. See L<Crypt::Sodium::XS::ProtMem>.

Returns a L<Crypt::Sodium::XS::MemVault>: a new secret key of L</KEYBYTES>
bytes.

=head2 shorthash

  my $hash = $shorthash->shorthash($message, $key);

C<$message> is the message to hash. It may be a L<Crypt::Sodium::XS::MemVault>.

C<$key> is the secret key used in the hash. It must be L</KEYBYTES> bytes. It
may be a L<Crypt::Sodium::XS::MemVault>.

Returns the hash output of L</BYTES> bytes.

=head2 BYTES

  my $hash_size = $shorthash->BYTES;

Returns the size, in bytes, of hash output.

=head2 KEYBYTES

  my $key_size = $shorthash->KEYBYTES;

Returns the size, in bytes, of a secret key.

=head1 PRIMITIVES

=over 4

=item * siphash24 (default)

=item * siphashx24

=back

=head1 FUNCTIONS

The object API above is the recommended way to use this module. The functions
and constants documented below can be imported instead or in addition.

Nothing is exported by default. A C<:default> tag imports the functions and
constants documented below. A separate C<:E<lt>primitiveE<gt>> import tag is
provided for each of the primitives listed in L</PRIMITIVES>. These tags import
the C<shorthash_E<lt>primitiveE<gt>_*> functions and constants for that
primitive. A C<:all> tag imports everything.

=head2 shorthash_keygen

=head2 shorthash_E<lt>primitiveE<gt>_keygen

  my $key = shorthash_keygen($flags);

Same as L</keygen>.

=head2 shorthash

  my $hash = shorthash($message, $key);

Same as L</shorthash>.

=head1 CONSTANTS

=head2 shorthash_PRIMITIVE

  my $default_primitive = shorthash_PRIMITIVE();

Returns the name of the default primitive.

=head2 shorthash_BYTES

  my $hash_size = shorthash_BYTES();

Same as L</BYTES>.

=head2 shorthash_KEYBYTES

  my $key_size = shorthash_KEYBYTES();

Same as L</KEYBYTES>.

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<https://doc.libsodium.org/hashing/short-input_hashing>

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
