# ===========================================================================
# Crypt::GCrypt:MPI
#
# Perl interface to multi-precision integers from the GNU Cryptographic library
#
# Author: Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>,
#         Alessandro Ranellucci E<lt>aar@cpan.orgE<gt>
# Copyright © 2009.
#
# Use this software AT YOUR OWN RISK.
# See below for documentation.
#

package Crypt::GCrypt::MPI;

use strict;
use warnings;

use Crypt::GCrypt;

1;
__END__

=encoding utf8

=head1 NAME

Crypt::GCrypt::MPI - Perl interface to multi-precision integers from the GNU Cryptographic library

=head1 SYNOPSIS

  use Crypt::GCrypt::MPI;

  my $mpi = Crypt::GCrypt::MPI->new();

=head1 ABSTRACT

Crypt::GCrypt::MPI provides an object interface to multi-precision
integers from the C libgcrypt library.

=head1 BASIC OPERATIONS

=head2 new()

Create a new multi-precision integer.

  my $mpi = Crypt::GCrypt::MPI::new(
    secure => 1,
    value => 20,
  );

No parameters are required.  If only one parameter is given, it is
treated as the "value" parameter.  Available parameters:

=over 4

=item value

The initial value of the MPI.  This can be an integer, a string, or
another Crypt::GCrypt::MPI.  (It would also be nice to be able to
initialize it with a Math::Int).

=item secure

If this parameter evaluates to non-zero, initialize the MPI using
secure memory, if possible.

=item format

If the value is a string, the format parameter suggests how to convert
the string.  See CONVERSION FORMATS for the available formats.
Defaults to Crypt::GCrypt::MPI::FMT_STD.

=back

=head2 set()

Copies the value of the other Crypt::GCrypt::MPI object.

  $mpi->set($othermpi);

=head2 swap()

Exchanges the value with the value of another Crypt::GCrpyt::MPI
object:

  $mpi->swap($othermpi);

=head2 is_secure()

Returns true if the Crypt::GCrypt::MPI uses secure memory, where
possible.

=head2 cmp($other)

Compares this object against another Crypt::GCrypt::MPI object,
returning 0 if the two values are equal, positive if this value is
greater, negative if $other is greater.

=head2 mutually_prime($other)

Compares this object against another Crypt::GCrypt::MPI object,
returning true only if the two values share no factors in common other
than 1.

=head2 copy()

Returns a new Crypt::GCrypt::MPI object, with the contents identical
to this one.  This is different from using the assignment operator
(=), which just makes two references to the same object.  For example:

 $b = new Crypt::GCrypt::MPI(15);
 $a = $b;
 $b->add(1); # $a points to the same object,
             # so both $a and $b contain 16.

 $a = $b->copy(); # $a and $b are both 16, but
                  # different objects; no risk of
                  # double-free.
 $b->add(1); # $a == 16, $b == 17

If $b is a Crypt::GCrypt::MPI object, then "$a = $b->copy();" is
identical to "$a = Crypt::GCrypt::MPI->new($b);"

=head1 CALCULATIONS

All calculation operations modify the object they are called on, and
return the same object, so you can chain them like this:

 $g->addm($a, $m)->mulm($b, $m)->gcd($x);

If you don't want an operation to affect the initial object, use the
copy() operator:

 $h = $g->copy()->addm($a, $m)->mulm($b, $m)->gcd($x);

=head2 add($other)

Adds the value of $other to this MPI.

=head2 addm($other, $modulus)

Adds the value of $other to this MPI, modulo the value of $modulus.

=head2 sub($other)

Subtracts the value of $other from this MPI.

=head2 subm($other, $modulus)

Subtracts the value of $other from this MPI, modulo the value of $modulus.

=head2 mul($other)

Multiply this MPI by the value of $other.

=head2 mulm($other, $modulus)

Multiply this MPI by the value of $other, modulo the value of $modulus.

=head2 mul_2exp($e)

Multiply this MPI by 2 raised to the power of $e (this is a leftward
bitshift)

=head2 div($other)

Divide this MPI by the value of $other, leaving the integer quotient.
(This is integer division)

=head2 mod($other)

Divide this MPI by the value of $other, leaving the integer remainder.
(This is the modulus operation)

=head2 powm($other, $modulus)

Raise this MPI to the power of $other, modulo the value of $modulus.

=head2 invm($modulus)

Find the multiplicative inverse of this MPI, modulo $modulus.

=head2 gcd($other)

Find the greatest common divisor of this MPI and $other.

=head1 OUTPUT AND DEBUGGING

=head2 dump()

Send the MPI to the libgcrypt debugging stream.

=head2 print($format)

Return a string with the data of this MPI, in a given format.  See
CONVERSION FORMATS for the available formats.

=head1 CONVERSION FORMATS

The available printing and scanning formats are all in the
Crypt::GCrypt::MPI namespace, and have the same meanings as in gcrypt.

=head2 FMT_STD

Two's complement representation.

=head2 FMT_PGP

Same as FMT_STD, but with two-byte length header, as used in OpenPGP.
(Only works for non-negative values)

=head2 FMT_SSH

Same as FMT_STD, but with four-byte length header, as used by OpenSSH.

=head2 FMT_HEX

Hexadecimal string in ASCII.

=head2 FMT_USG

Simple unsigned integer.

=head1 BUGS AND FEEDBACK

Crypt::GCrypt::MPI does not currently auto-convert to and from
Math::BigInt objects, even though it should.

Other than that, here are no known bugs. You are very welcome to write
mail to the maintainer (aar@cpan.org) with your contributions, comments,
suggestions, bug reports or complaints.

=head1 AUTHORS AND CONTRIBUTORS

Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>

Alessandro Ranellucci E<lt>aar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © Daniel Kahn Gillmor.
Crypt::GCrypt::MPI is free software, you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

This module was initially inspired by the GCrypt.pm bindings made by
Robert Bihlmeyer in 2002. Thanks to users who give feedback and submit
patches (see Changelog).

=head1 DISCLAIMER

This software is provided by the copyright holders and contributors ``as
is'' and any express or implied warranties, including, but not limited to,
the implied warranties of merchantability and fitness for a particular
purpose are disclaimed. In no event shall the regents or contributors be
liable for any direct, indirect, incidental, special, exemplary, or
consequential damages (including, but not limited to, procurement of
substitute goods or services; loss of use, data, or profits; or business
interruption) however caused and on any theory of liability, whether in
contract, strict liability, or tort (including negligence or otherwise)
arising in any way out of the use of this software, even if advised of the
possibility of such damage.

=cut
