package Crypt::Sodium::XS::Util;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

our @EXPORT_OK = (qw(
  sodium_add
  sodium_base642bin
  sodium_bin2base64
  sodium_bin2hex
  sodium_compare
  sodium_hex2bin
  sodium_increment
  sodium_is_zero
  sodium_memcmp
  sodium_sub
  sodium_random_bytes
  sodium_memzero
  sodium_version_string
));

our %EXPORT_TAGS = (all => \@EXPORT_OK, functions => \@EXPORT_OK);

1;

__END__

=encoding utf8

Crypt::Sodium::XS::Util - libsodium utilities

=head1 SYNOPSIS

  use Crypt::Sodium::XS::Util ':all';

  ...

=head1 DESCRIPTION

Provides access to libsodium-provided utilities. IMPROVEME.

B<NOTE>: Except where otherwise mentioned (see L</sodium_random_bytes>), these
functions are not intended for use with sensitive data.
L<Crypt::Sodium::XS::MemVault> provides much of the same functionality for use
with sensitive data.

=head1 FUNCTIONS

Nothing is exported by default. The tag C<:functions> imports all
L</FUNCTIONS>. The tag C<:all> imports everything.

=head2 sodium_add

  my $sum = sodium_add($string, $other_string);

Add C<$other_string> to C<$string> as arbitrarily long little-endian unsigned
numbers. This function runs in constant time for a given length.

Strings may be of arbitrary length. C<$sum> will be the length of the longer
operand (C<$string> or C<$other_string>). Addition wraps if C<$sum> would
overflow.

=head2 sodium_bin2hex

  my $string = sodium_bin2hex($bytes);

No real advantage over C<unpack("H*", $bytes)>.

=head2 sodium_compare

  my $lt_eq_or_gt = sodium_compare($string, $other_string, $length);

Fixed-time (for a given length) comparison of bytes C<$string> and
C<$other_string> as little-endian arbitrary-length integers. Returns C<0> if
the bytes are equal, C<-1> if C<$string> is less than C<$other_string>, or C<1>
if C<$string> is greater. Comparible to the C<cmp> perl operator.

C<$length> is optional iif C<$string> and C<$other_string> are equal lengths.
If provided, only C<$length> bytes are compared.

=head2 sodium_hex2bin

  my $bytes = sodium_hex2bin($string);

No real advantage over C<pack("H*", $bytes)>. Stops parsing at any invalid hex
bytes ([0-9a-f] case insensitive). C<$bytes> will be empty if C<$string> could
not be validly interpreted as hex (i.e., if the output would not be a multiple
of 8 bits.)

=head2 sodium_increment

  my $incremented = sodium_increment($string);

Interpret C<$string> as an arbitrarily long little-endian unsigned number and
add one to it. This is intended for the return values of nonce functions. This
function runs in constant time for a given C<$string> length. Incrementing
wraps if $string would overflow.

=head2 sodium_is_zero

  my $is_zero = sodium_is_zero($string)

Returns true iif C<$string> consists only of null bytes. Returns false
otherwise. This function runs in constant time for a given C<$string> length.

=head2 sodium_memcmp

  my $is_equal = sodium_memcmp($string, $other_string, $length);

Fixed-time (for a given length) comparison of bytes C<$string> and
C<$other_string> as little-endian arbitrary-length integers. Returns true if
the bytes are equal, false otherwise.

C<$length> is optional iif C<$string> and C<$other_string> are equal lengths.
If provided, only C<$length> bytes are compared.

=head2 sodium_random_bytes

  my $bytes = sodium_random_bytes($num_of_bytes, $use_memory_vault, $flags);

Generates unpredictable sequence of C<$num_of_bytes> bytes.

The length of the returned C<$bytes> equals C<$num_of_bytes>.

Depending on the boolean C<$use_memory_vault>, returns either a plain scalar
(if false or omitted), or a L<Crypt::Sodium::XS::MemVault> object (if true).
Either will contain C<$num_of_bytes> bytes of random data. For generating
random keys and nonces, it is preferable to use the provided C<*_keygen()>,
C<*_keypair()>, and C<*_nonce()> functions.

If C<$use_memory_vault> is true, C<$flags> will be the memory protection flags
of the returned object. See L<Crypt::Sodium::XS::ProtMem>. The default is
L<Crypt::Sodium::XS::ProtMem/protmem_flags_memvault_default>.

=head2 sodium_sub

  my $diff = sodium_sub($string, $other_string);

Subtract C<$other_string> from C<$string> as arbitrarily long little-endian
unsigned numbers. This function runs in constant time for a given length.

Strings may be of arbitrary length. C<$diff> will be the length of the longer
operand (C<$string> or C<$other_string>). Subtraction wraps if C<$diff> would
overflow.

=head2 sodium_memzero

  sodium_memzero($x);
  sodium_memzero($x, $y, $z, ...);

Helper utility for clearing out sensitive memory contents. The string values of
any given arguments will be overwritten with (the same length of) null bytes.

B<NOTE>: this is an interface to the libsodium C<sodium_memzero> function.

=head1 SEE ALSO

=over 4

=item * L<libsodium|https://doc.libsodium.org/helpers>

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
