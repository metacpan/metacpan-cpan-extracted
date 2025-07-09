package Crypt::Sodium::XS::OO::shorthash;
use strict;
use warnings;

use Crypt::Sodium::XS::shorthash;
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

sub primitives { keys %methods }

sub BYTES { my $self = shift; goto $methods{$self->{primitive}}->{BYTES}; }
sub KEYBYTES { my $self = shift; goto $methods{$self->{primitive}}->{KEYBYTES}; }
sub PRIMITIVE { my $self = shift; goto $methods{$self->{primitive}}->{PRIMITIVE}; }
sub keygen { my $self = shift; goto $methods{$self->{primitive}}->{keygen}; }
sub shorthash { my $self = shift; goto $methods{$self->{primitive}}->{shorthash}; }

1;

__END__

=encoding utf8

=head1 NAME

Crypt::Sodium::XS::OO::shorthash - Short-input hashing

=head1 SYNOPSIS

  use Crypt::Sodium::XS;

  my $shorthash = Crypt::Sodium::XS->shorthash;

  my $key = $shorthash->keygen;
  my $msg = "short input";

  my $hash = $shorthash->shorthash($msg, $key);

=head1 DESCRIPTION

L<Crypt::Sodium::XS::OO::shorthash> outputs short but unpredictable (without
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

=head2 new

  my $shorthash = Crypt::Sodium::XS::OO::shorthash->new;
  my $shorthash
    = Crypt::Sodium::XS::OO::shorthash->new(primitive => 'siphash24');
  my $shorthash = Crypt::Sodium::XS->shorthash;

Returns a new secretstream object for the given primitive. If not given, the
default primitive is C<default>.

=head1 METHODS

=head2 PRIMITIVE

  my $default_primitive = $shorthash->PRIMITIVE;

=head2 BYTES

  my $hash_length = $shorthash->BYTES;

=head2 KEYBYTES

  my $key_length = $shorthash->KEYBYTES;

=head2 primitives

  my @primitives = $pwhash->primitives;

Returns a list of all supported primitive names (including 'default').

=head2 keygen

  my $key = $shorthash->keygen;

=head2 shorthash

  my $hash = $shorthash->shorthash($message, $key);

=head1 SEE ALSO

=over 4

=item L<Crypt::Sodium::XS>

=item L<Crypt::Sodium::XS::shorthash>

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
