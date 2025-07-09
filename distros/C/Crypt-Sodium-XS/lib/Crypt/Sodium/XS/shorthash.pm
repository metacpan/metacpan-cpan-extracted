package Crypt::Sodium::XS::shorthash;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

_define_constants();

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

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::shorthash - Short-input hashing

=head1 SYNOPSIS

    use Crypt::Sodium::XS::shorthash ":default";

  my $key = shorthash_keygen;
  my $msg = "short input";

  my $hash = shorthash($msg, $key);

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

=head1 FUNCTIONS

Nothing is exported by default. A C<:default> tag imports the functions and
constants as documented below. A separate import tag is provided for each of
the primitives listed in L</PRIMITIVES>. For example, C<:siphash24> imports
C<shorthash_siphash24>. You should use at least one import tag.

=head2 shorthash_keygen

  my $key = shorthash_keygen();

=head2 shorthash

  my $hash = shorthash($message, $key);

=head1 CONSTANTS

=head2 shorthash_PRIMITIVE

  my $default_primitive = shorthash_PRIMITIVE();

=head2 shorthash_BYTES

  my $hash_length = shorthash_BYTES();

=head2 shorthash_KEYBYTES

  my $key_length = shorthash_KEYBYTES();

=head1 PRIMITIVES

All functions have C<shorthash_E<lt>primitiveE<gt>>-prefixed counterparts
(e.g., shorthash_siphashx24_keygen).

=over 4

=item * siphash24

=item * siphashx24

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::OO::shorthash>

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
