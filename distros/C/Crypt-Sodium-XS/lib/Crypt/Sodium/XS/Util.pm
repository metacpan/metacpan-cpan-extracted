package Crypt::Sodium::XS::Util;
use strict;
use warnings;

use Crypt::Sodium::XS;
use Exporter 'import';

our @EXPORT_OK = (qw(
  sodium_add
  sodium_bin2hex
  sodium_compare
  sodium_hex2bin
  sodium_increment
  sodium_is_zero
  sodium_memcmp
  sodium_memzero
  sodium_pad
  sodium_sub
  sodium_random_bytes
  sodium_unpad
  sodium_version_string
));

our %EXPORT_TAGS = (all => \@EXPORT_OK, functions => \@EXPORT_OK);

1;

__END__

=encoding utf8

=head1 NAME

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

  my $sum = sodium_add($bytes, $other_bytes);

Add C<$other_bytes> to C<$bytes> as arbitrarily long little-endian unsigned
numbers. This function runs in constant time for a given length.

Byte strings may be of arbitrary size. C<$sum> will be the size of the larger
operand. Addition wraps if C<$sum> would overflow.

=head2 sodium_bin2hex

  my $string = sodium_bin2hex($bytes);

No real advantage over C<unpack("H*", $bytes)>.

=head2 sodium_compare

  my $lt_eq_or_gt = sodium_compare($bytes, $other_bytes, $size);

Returns C<0> if the bytes are equal, C<-1> if C<$bytes> is less than
C<$other_bytes>, or C<1> if C<$mv> is greater. This function runs in fixed-time
(for a given size), and compares bytes as little-endian arbitrary-length
integers. Comparible to the C<cmp> perl operator.

C<$size> is optional iif C<$bytes> and C<$other_bytes> are equal sizes.
If provided, only C<$size> bytes are compared.

B<Note>: This function is similar to L<memcmp(3)>; that is, it returns -1, 0,
or 1 for the comparison results. For simple true/false equality comparisons,
see L</sodium_memcmp>. The naming is chosen here to be consistent with
libsodium.

=head2 sodium_hex2bin

  my $bytes = sodium_hex2bin($string);

No real advantage over C<pack("H*", $bytes)>. Stops parsing at any invalid hex
bytes ([0-9a-f] case insensitive). C<$bytes> will be empty if C<$string> could
not be validly interpreted as hex (i.e., if the output would not be a multiple
of 8 bits.)

=head2 sodium_increment

  my $incremented = sodium_increment($bytes);

Interpret C<$bytes> as an arbitrarily long little-endian unsigned number and
add one to it. This is intended for the return values of nonce functions. This
function runs in constant time for a given C<$bytes> size. Incrementing wraps
if C<$incremented> would overflow.

=head2 sodium_is_zero

  my $is_zero = sodium_is_zero($bytes)

Returns true iif C<$bytes> consists only of null bytes. Returns false
otherwise. This function runs in constant time for a given C<$bytes> length.

=head2 sodium_memcmp

  my $is_equal = sodium_memcmp($bytes, $other_bytes, $size);

Returns true if the operands are exactly equal, false otherwise. This method
runs in fixed-time (for a given size), and compares bytes as little-endian
arbitrary-length integers.

C<$size> is optional iif C<$bytes> and C<$other_bytes> are equal sizes. If
provided, only C<$size> bytes are compared. B<Note>: Croaks if operands are
unequal sizes and C<$size> was not provided, or if C<$size> is larger than
either of the operands.

When a comparison involves secret data (e.g. a key, a password, etc.), it is
critical to use a constant-time comparison function. This property does not
relate to computational complexity: it means the time needed to perform the
comparison is the same for all data of the same size. The goal is to mitigate
side-channel attacks.

B<Note>: L</sodium_memcmp> is different than L<memcmp(3)>. This method returns
only true/false for equality, not -1, 0, or 1 for the comparison results. For
that, see L</sodium_compare>. The naming is chosen here to be consistent with
libsodium.

=head2 sodium_pad

=head2 sodium_unpad

  my $padded = sodium_pad($bytes, $blocksize);
  my $unpadded = sodium_unpad($bytes, $blocksize);

Returns C<$bytes> padded or unpadded respectively, to the next multiple of
C<$blocksize> bytes.

These functions use the ISO/IEC 7816-4 padding algorithm. It supports arbitrary
block sizes, ensures that the padding data are checked for computing the
unpadded length, and is more resistant to some classes of attacks than other
standard padding algorithms.

Notes:

=over 4

Padding should be applied before encryption and removed after decryption.

Usage of padding to hide the length of a password is not recommended. A client
willing to send a password to a server should hash it instead, even with a
single iteration of the hash function.

This ensures that the length of the transmitted data is constant and that the
server doesn’t effortlessly get a copy of the password.

Applications may eventually leak the unpadded length via side channels, but the
sodium_pad() and sodium_unpad() functions themselves try to minimize side
channels for a given length & <block size mask> value.

=back

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

  my $diff = sodium_sub($bytes, $other_bytes);

Subtract C<$other_bytes> from C<$bytes> as arbitrarily long little-endian
unsigned numbers. This function runs in constant time for a given length.

Byte strings may be of arbitrary size. C<$diff> will be the size of the larger
operand. Subtraction wraps if C<$diff> would overflow.

=head2 sodium_memzero

  sodium_memzero($x);
  sodium_memzero($x, $y, $z, ...);

Helper utility for clearing out sensitive memory contents. The PV values of any
given arguments will be overwritten with (the same length of) null bytes.

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
