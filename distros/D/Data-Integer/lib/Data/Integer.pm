=head1 NAME

Data::Integer - details of the native integer data type

=head1 SYNOPSIS

    use Data::Integer qw(natint_bits);

    $n = natint_bits;

    # and other constants; see text

    use Data::Integer qw(nint sint uint nint_is_sint nint_is_uint);

    $ni = nint($ni);
    $si = sint($si);
    $ui = uint($ui);
    if(nint_is_sint($ni)) { ...
    if(nint_is_uint($ni)) { ...

    use Data::Integer qw(
	nint_sgn sint_sgn uint_sgn
	nint_abs sint_abs uint_abs
	nint_cmp sint_cmp uint_cmp
	nint_min sint_min uint_min
	nint_max sint_max uint_max
	nint_neg sint_neg uint_neg
	nint_add sint_add uint_add
	nint_sub sint_sub uint_sub);

    $sn = nint_sgn($ni);
    $sn = sint_sgn($si);
    $sn = uint_sgn($ui);
    $ni = nint_abs($ni);
    $si = sint_abs($si);
    $ui = uint_abs($ui);
    @sorted_nints = sort { nint_cmp($a, $b) } @nints;
    @sorted_sints = sort { sint_cmp($a, $b) } @sints;
    @sorted_uints = sort { uint_cmp($a, $b) } @uints;
    $ni = nint_min($na, $nb);
    $si = sint_min($sa, $sb);
    $ui = uint_min($ua, $ub);
    $ni = nint_max($na, $nb);
    $si = sint_max($sa, $sb);
    $ui = uint_max($ua, $ub);
    $ni = nint_neg($ni);
    $si = sint_neg($si);
    $ui = uint_neg($ui);
    $ni = nint_add($na, $nb);
    $si = sint_add($sa, $sb);
    $ui = uint_add($ua, $ub);
    $ni = nint_sub($na, $nb);
    $si = sint_sub($sa, $sb);
    $ui = uint_sub($ua, $ub);

    use Data::Integer qw(
	sint_shl uint_shl
	sint_shr uint_shr
	sint_rol uint_rol
	sint_ror uint_ror);

    $si = sint_shl($si, $dist);
    $ui = uint_shl($ui, $dist);
    $si = sint_shr($si, $dist);
    $ui = uint_shr($ui, $dist);
    $si = sint_rol($si, $dist);
    $ui = uint_rol($ui, $dist);
    $si = sint_ror($si, $dist);
    $ui = uint_ror($ui, $dist);

    use Data::Integer qw(
	nint_bits_as_sint nint_bits_as_uint
	sint_bits_as_uint uint_bits_as_sint);

    $si = nint_bits_as_sint($ni);
    $ui = nint_bits_as_uint($ni);
    $ui = sint_bits_as_uint($si);
    $si = uint_bits_as_sint($ui);

    use Data::Integer qw(
	sint_not uint_not
	sint_and uint_and
	sint_nand uint_nand
	sint_andn uint_andn
	sint_or uint_or
	sint_nor uint_nor
	sint_orn uint_orn
	sint_xor uint_xor
	sint_nxor uint_nxor
	sint_mux uint_mux);

    $si = sint_not($si);
    $ui = uint_not($ui);
    $si = sint_and($sa, $sb);
    $ui = uint_and($ua, $ub);
    $si = sint_nand($sa, $sb);
    $ui = uint_nand($ua, $ub);
    $si = sint_andn($sa, $sb);
    $ui = uint_andn($ua, $ub);
    $si = sint_or($sa, $sb);
    $ui = uint_or($ua, $ub);
    $si = sint_nor($sa, $sb);
    $ui = uint_nor($ua, $ub);
    $si = sint_orn($sa, $sb);
    $ui = uint_orn($ua, $ub);
    $si = sint_xor($sa, $sb);
    $ui = uint_xor($ua, $ub);
    $si = sint_nxor($sa, $sb);
    $ui = uint_nxor($ua, $ub);
    $si = sint_mux($sa, $sb, $sc);
    $ui = uint_mux($ua, $ub, $uc);

    use Data::Integer qw(
	sint_madd uint_madd
	sint_msub uint_msub
	sint_cadd uint_cadd
	sint_csub uint_csub
	sint_sadd uint_sadd
	sint_ssub uint_ssub);

    $si = sint_madd($sa, $sb);
    $ui = uint_madd($ua, $ub);
    $si = sint_msub($sa, $sb);
    $ui = uint_msub($ua, $ub);
    ($carry, $si) = sint_cadd($sa, $sb, $carry);
    ($carry, $ui) = uint_cadd($ua, $ub, $carry);
    ($carry, $si) = sint_csub($sa, $sb, $carry);
    ($carry, $ui) = uint_csub($ua, $ub, $carry);
    $si = sint_sadd($sa, $sb);
    $ui = uint_sadd($ua, $ub);
    $si = sint_ssub($sa, $sb);
    $ui = uint_ssub($ua, $ub);

    use Data::Integer qw(natint_hex hex_natint);

    print natint_hex($value);
    $value = hex_natint($string);

=head1 DESCRIPTION

This module is about the native integer numerical data type.  A native
integer is one of the types of datum that can appear in the numeric part
of a Perl scalar.  This module supplies constants describing the native
integer type.

There are actually two native integer representations: signed and
unsigned.  Both are handled by this module.

=head1 NATIVE INTEGERS

Each native integer format represents a value using binary place
value, with some fixed number of bits.  The number of bits is the
same for both signed and unsigned representations.  In each case
the least-significant bit has the value 1, the next 2, the next 4,
and so on.  In the unsigned representation, this pattern continues up
to and including the most-significant bit, which for a 32-bit machine
therefore has the value 2^31 (2147483648).  The unsigned format cannot
represent any negative numbers.

In the signed format, the most-significant bit is exceptional, having
the negation of the value that it does in the unsigned format.  Thus on
a 32-bit machine this has the value -2^31 (-2147483648).  Values with
this bit set are negative, and those with it clear are non-negative;
this bit is also known as the "sign bit".

It is usual in machine arithmetic to use one of these formats at a
time, for example to add two signed numbers yielding a signed result.
However, Perl has a trick: a scalar with a native integer value contains
an additional flag bit which indicates whether the signed or unsigned
format is being used.  It is therefore possible to mix signed and unsigned
numbers in arithmetic, at some extra expense.

=cut

package Data::Integer;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.007";

use parent "Exporter";
our @EXPORT_OK = qw(
	natint_bits
	min_nint max_nint min_natint max_natint
	min_sint max_sint min_signed_natint max_signed_natint
	min_uint max_uint min_unsigned_natint max_unsigned_natint
	nint sint uint
	nint_is_sint nint_is_uint
	nint_sgn sint_sgn uint_sgn
	nint_abs sint_abs uint_abs
	nint_cmp sint_cmp uint_cmp
	nint_min sint_min uint_min
	nint_max sint_max uint_max
	nint_neg sint_neg uint_neg
	nint_add sint_add uint_add
	nint_sub sint_sub uint_sub
	sint_shl uint_shl
	sint_shr uint_shr
	sint_rol uint_rol
	sint_ror uint_ror
	nint_bits_as_sint nint_bits_as_uint
	sint_bits_as_uint uint_bits_as_sint
	sint_not uint_not
	sint_and uint_and
	sint_nand uint_nand
	sint_andn uint_andn
	sint_or uint_or
	sint_nor uint_nor
	sint_orn uint_orn
	sint_xor uint_xor
	sint_nxor uint_nxor
	sint_mux uint_mux
	sint_madd uint_madd
	sint_msub uint_msub
	sint_cadd uint_cadd
	sint_csub uint_csub
	sint_sadd uint_sadd
	sint_ssub uint_ssub
	natint_hex hex_natint
);

=head1 CONSTANTS

Each of the extreme-value constants has two names, a short one and a
long one.  The short names are more convenient to use, but the long
names are clearer in a context where other similar constants exist.

Due to the risks of Perl changing the behaviour of a native integer value
that has been involved in floating point arithmetic (see L</BUGS>),
the extreme-value constants are actually non-constant functions that
always return a fresh copy of the appropriate value.  The returned value
is always a pure native integer value, unsullied by floating point or
string operations.

=over

=item natint_bits

The width, in bits, of the native integer data types.

=cut

# Count the number of bits in native integers by repeatedly shifting a bit
# left until it turns into the sign bit.  "use integer" forces the use of a
# signed integer representation.
BEGIN {
	use integer;
	my $bit_count = 1;
	my $test_bit = 1;
	while($test_bit > 0) {
		$bit_count += 1;
		$test_bit <<= 1;
	}
	my $natint_bits = $bit_count;
	*natint_bits = sub () { $natint_bits };
}

=item min_nint

=item min_natint

The minimum representable value in either representation.  This is
-2^(natint_bits - 1).

=cut

BEGIN {
	my $min_nint = do { use integer; 1 << (natint_bits - 1) };
	*min_natint = *min_nint = sub() { my $ret = $min_nint };
}

=item max_nint

=item max_natint

The maximum representable value in either representation.  This is
2^natint_bits - 1.

=cut

BEGIN {
	my $max_nint = ~0;
	*max_natint = *max_nint = sub() { my $ret = $max_nint };
}

=item min_sint

=item min_signed_natint

The minimum representable value in the signed representation.  This is
-2^(natint_bits - 1).

=cut

BEGIN { *min_signed_natint = *min_sint = \&min_nint; }

=item max_sint

=item max_signed_natint

The maximum representable value in the signed representation.  This is
2^(natint_bits - 1) - 1.

=cut

BEGIN {
	my $max_sint = ~min_sint;
	*max_signed_natint = *max_sint = sub() { my $ret = $max_sint };
}

=item min_uint

=item min_unsigned_natint

The minimum representable value in the unsigned representation.
This is zero.

=cut

BEGIN {
	my $min_uint = 0;
	*min_unsigned_natint = *min_uint = sub() { my $ret = $min_uint };
}

=item max_uint

=item max_unsigned_natint

The maximum representable value in the unsigned representation.  This is
2^natint_bits - 1.

=cut

BEGIN { *max_unsigned_natint = *max_uint = \&max_nint; }

=back

=head1 FUNCTIONS

Each "nint_", "sint_", or "uint_" function operates on one of the three
integer formats.  "nint_" functions operate on Perl's union of signed
and unsigned; "sint_" functions operate on signed integers; and "uint_"
functions operate on unsigned integers.  Except where indicated otherwise,
the function returns a value of its primary type.

Parameters I<A>, I<B>, and I<C>, where present, must be numbers of
the appropriate type: specifically, with a numerical value that can be
represented in that type.  If there are multiple flavours of zero, due
to floating point funkiness, all zeroes are treated the same.  Parameters
with other names have other requirements, explained with each function.

The functions attempt to detect unsuitable arguments, and C<die> if
an invalid argument is detected, but they can't notice some kinds of
incorrect argument.  Generally, it is the caller's responsibility to
provide a sane numerical argument, and supplying an invalid argument will
cause mayhem.  Only the numeric value of plain scalar arguments is used;
the string value is completely ignored, so dualvars are not a problem.

=head2 Canonicalisation and classification

These are basic glue functions.

=over

=item nint(A)

=item sint(A)

=item uint(A)

These functions each take an argument in a specific integer format and
return its numerical value.  This is the argument canonicalisation that is
performed by all of the functions in this module, presented in isolation.

=cut

sub nint($) {
	my $tval = $_[0];
	croak "not a native integer"
		unless int($tval) == $tval && $tval >= min_nint &&
			$tval <= max_nint;
	return ($tval = $_[0]) < 0 ? do { use integer; 0 | $_[0] } : 0 | $_[0];
}

sub sint($) {
	my $tval = $_[0];
	croak "not a signed native integer"
		unless int($tval) == $tval && $tval >= min_sint &&
			$tval <= max_sint;
	my $val = do { use integer; 0 | $_[0] };
	croak "not a signed native integer"
		if $tval >= 0 && do { use integer; $val < 0 };
	return $val;
}

sub uint($) {
	my $tval = $_[0];
	croak "not an unsigned native integer"
		unless int($tval) == $tval && $tval >= min_uint &&
			$tval <= max_uint;
	return 0 | $_[0];
}

=item nint_is_sint(A)

Takes a native integer of either type.  Returns a truth value indicating
whether this value can be exactly represented as a signed native integer.

=cut

sub nint_is_sint($) {
	my $val = nint($_[0]);
	return (my $tval = $val) < 0 ||
		do { use integer; ($val & min_sint) == 0 };
}

=item nint_is_uint(A)

Takes a native integer of either type.  Returns a truth value indicating
whether this value can be exactly represented as an unsigned native
integer.

=cut

sub nint_is_uint($) { nint($_[0]) >= 0 }

=back

=head2 Arithmetic

These functions operate on numerical values rather than just bit patterns.
They will all C<die> if the true numerical result doesn't fit into the
result format, rather than give a wrong answer.

=over

=item nint_sgn(A)

=item sint_sgn(A)

=item uint_sgn(A)

Returns +1 if the argument is positive, 0 if the argument is zero,
or -1 if the argument is negative.

=cut

sub nint_sgn($) { nint($_[0]) <=> 0 }

sub sint_sgn($) { use integer; sint($_[0]) <=> 0 }

sub uint_sgn($) { use integer; uint($_[0]) == 0 ? 0 : +1 }

=item nint_abs(A)

=item sint_abs(A)

=item uint_abs(A)

Absolute value (magnitude, discarding sign).

=cut

sub nint_abs($) {
	my $a = nint($_[0]);
	if((my $tval = $a) >= 0) {
		return $a;
	} elsif(do { use integer; $a == min_sint }) {
		return 0 | min_sint;
	} else {
		use integer;
		return -$a;
	}
}

sub sint_abs($) {
	my $a = sint($_[0]);
	use integer;
	croak "integer overflow" if $a == min_sint;
	return $a < 0 ? -$a : $a;
}

*uint_abs = \&uint;

=item nint_cmp(A, B)

=item sint_cmp(A, B)

=item uint_cmp(A, B)

Arithmetic comparison.  Returns -1, 0, or +1, indicating whether A is
less than, equal to, or greater than B.

=cut

sub nint_cmp($$) {
	my($a, $b) = (nint($_[0]), nint($_[1]));
	if((my $ta = $a) < 0) {
		if((my $tb = $b) < 0) {
			use integer;
			return $a <=> $b;
		} else {
			return -1;
		}
	} else {
		if((my $tb = $b) < 0) {
			return 1;
		} else {
			use integer;
			return ($a ^ min_sint) <=> ($b ^ min_sint);
		}
	}
}

sub sint_cmp($$) { use integer; sint($_[0]) <=> sint($_[1]) }

sub uint_cmp($$) {
	use integer;
	return (uint($_[0]) ^ min_sint) <=> (uint($_[1]) ^ min_sint);
}

=item nint_min(A, B)

=item sint_min(A, B)

=item uint_min(A, B)

Arithmetic minimum.  Returns the arithmetically lesser of the two
arguments.

=cut

sub nint_min($$) {
	my($a, $b) = (nint($_[0]), nint($_[1]));
	if((my $ta = $a) < 0) {
		if((my $tb = $b) < 0) {
			use integer;
			return $a < $b ? $a : $b;
		} else {
			return $a;
		}
	} else {
		if((my $tb = $b) < 0) {
			return $b;
		} else {
			use integer;
			return ($a ^ min_sint) < ($b ^ min_sint) ? $a : $b;
		}
	}
}

sub sint_min($$) {
	my($a, $b) = (sint($_[0]), sint($_[1]));
	use integer;
	return $a < $b ? $a : $b;
}

sub uint_min($$) {
	my($a, $b) = (uint($_[0]), uint($_[1]));
	use integer;
	return ($a ^ min_sint) < ($b ^ min_sint) ? $a : $b;
}

=item nint_max(A, B)

=item sint_max(A, B)

=item uint_max(A, B)

Arithmetic maximum.  Returns the arithmetically greater of the two
arguments.

=cut

sub nint_max($$) {
	my($a, $b) = (nint($_[0]), nint($_[1]));
	if((my $ta = $a) < 0) {
		if((my $tb = $b) < 0) {
			use integer;
			return $a < $b ? $b : $a;
		} else {
			return $b;
		}
	} else {
		if((my $tb = $b) < 0) {
			return $a;
		} else {
			use integer;
			return ($a ^ min_sint) < ($b ^ min_sint) ? $b : $a;
		}
	}
}

sub sint_max($$) {
	my($a, $b) = (sint($_[0]), sint($_[1]));
	use integer;
	return $a < $b ? $b : $a;
}

sub uint_max($$) {
	my($a, $b) = (uint($_[0]), uint($_[1]));
	use integer;
	return ($a ^ min_sint) < ($b ^ min_sint) ? $b : $a;
}

=item nint_neg(A)

=item sint_neg(A)

=item uint_neg(A)

Negation: returns -A.

=cut

sub nint_neg($) {
	my $a = nint($_[0]);
	if((my $ta = $a) <= 0) {
		return 0 | do { use integer; -$a };
	} else {
		use integer;
		my $neg = -$a;
		croak "integer overflow" if $neg >= 0;
		return $neg;
	}
}

sub sint_neg($) {
	my $a = sint($_[0]);
	use integer;
	croak "integer overflow" if $a == min_sint;
	return -$a;
}

sub uint_neg($) {
	use integer;
	croak "integer overflow" unless uint($_[0]) == 0;
	return my $zero = 0;
}

=item nint_add(A, B)

=item sint_add(A, B)

=item uint_add(A, B)

Addition: returns A + B.

=cut

sub nint_add($$) {
	my($a, $b) = (nint($_[0]), nint($_[1]));
	if((my $ta = $a) < 0) {
		if((my $tb = $b) < 0) {
			use integer;
			my $r = $a + $b;
			croak "integer overflow" if $r > $a;
			return $r;
		} else {
			use integer;
			my $r = $a + $b;
			$r = do { no integer; 0 | $r } if $r < $a;
			return $r;
		}
	} else {
		if((my $tb = $b) < 0) {
			use integer;
			my $r = $a + $b;
			$r = do { no integer; 0 | $r } if $r < $b;
			return $r;
		} else {
			use integer;
			my $r = $a + $b;
			croak "integer overflow"
				if ($r ^ min_sint) < ($a ^ min_sint);
			return do { no integer; 0 | $r };
		}
	}
}

sub sint_add($$) {
	my($a, $b) = (sint($_[0]), sint($_[1]));
	use integer;
	my $r = $a + $b;
	croak "integer overflow" if $b < 0 ? $r > $a : $r < $a;
	return $r;
}

sub uint_add($$) {
	my($a, $b) = (uint($_[0]), uint($_[1]));
	use integer;
	my $r = $a + $b;
	croak "integer overflow" if ($r ^ min_sint) < ($a ^ min_sint);
	return do { no integer; 0 | $r };
}

=item nint_sub(A, B)

=item sint_sub(A, B)

=item uint_sub(A, B)

Subtraction: returns A - B.

=cut

sub nint_sub($$) {
	my($a, $b) = (nint($_[0]), nint($_[1]));
	if((my $ta = $a) < 0) {
		if((my $tb = $b) < 0) {
			use integer;
			return $a - $b;
		} elsif(!($b & min_sint)) {
			use integer;
			my $r = $a - $b;
			croak "integer overflow" if $r >= 0;
			return $r;
		} else {
			croak "integer overflow";
		}
	} elsif(!($a & min_sint)) {
		if((my $tb = $b) < 0) {
			return 0 | do { use integer; $a - $b };
		} elsif(!($b & min_sint)) {
			use integer;
			return $a - $b;
		} else {
			use integer;
			my $r = $a - $b;
			croak "integer overflow" if $r >= 0;
			return $r;
		}
	} else {
		if((my $tb = $b) < 0) {
			use integer;
			my $r = $a - $b;
			croak "integer overflow" if $r >= 0;
			return do { no integer; 0 | $r };
		} elsif(!($b & min_sint)) {
			return 0 | do { use integer; $a - $b };
		} else {
			use integer;
			return $a - $b;
		}
	}
}

sub sint_sub($$) {
	my($a, $b) = (sint($_[0]), sint($_[1]));
	use integer;
	my $r = $a - $b;
	croak "integer overflow" if $b > 0 ? $r > $a : $r < $a;
	return $r;
}

sub uint_sub($$) {
	my($a, $b) = (uint($_[0]), uint($_[1]));
	use integer;
	my $r = $a - $b;
	croak "integer overflow" if ($r ^ min_sint) > ($a ^ min_sint);
	return do { no integer; 0 | $r };
}

=back

=head2 Bit shifting

These functions all operate on the bit patterns representing integers,
mostly ignoring the numerical values represented.  In most cases the
results for particular numerical arguments are influenced by the word
size, because that determines where a bit being left-shifted will drop
off the end of the word and where a bit will be shifted in during a
rightward shift.

With the exception of rightward shifts (see below), each pair of
functions performs exactly the same operations on the bit sequences.
There inevitably can't be any functions here that operate on Perl's union
of signed and unsigned; you must choose, by which function you call,
which type the result is to be tagged as.

=over

=item sint_shl(A, DIST)

=item uint_shl(A, DIST)

Bitwise left shift (towards more-significant bits).  I<DIST> is the
distance to shift, in bits, and must be an integer in the range [0,
natint_bits).  Zeroes are shifted in from the right.

=cut

sub sint_shl($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	use integer;
	return sint($val) << $dist;
}

sub uint_shl($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	no integer;
	return uint($val) << $dist;
}

=item sint_shr(A, DIST)

=item uint_shr(A, DIST)

Bitwise right shift (towards less-significant bits).  I<DIST> is the
distance to shift, in bits, and must be an integer in the range [0,
natint_bits).

When performing an unsigned right shift, zeroes are shifted in from the
left.  A signed right shift is different: the sign bit gets duplicated,
so right-shifting a negative number always gives a negative result.

=cut

sub sint_shr($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	use integer;
	return sint($val) >> $dist;
}

sub uint_shr($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	no integer;
	return uint($val) >> $dist;
}

=item sint_rol(A, DIST)

=item uint_rol(A, DIST)

Bitwise left rotation (towards more-significant bits, with the
most-significant bit wrapping round to the least-significant bit).
I<DIST> is the distance to rotate, in bits, and must be an integer in
the range [0, natint_bits).

=cut

sub sint_rol($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	$val = sint($val);
	return $val if $dist == 0;
	my $low_val = $val >> (natint_bits - $dist);
	use integer;
	return $low_val | ($val << $dist);
}

sub uint_rol($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	$val = uint($val);
	return $val if $dist == 0;
	return ($val >> (natint_bits - $dist)) | ($val << $dist);
}

=item sint_ror(A, DIST)

=item uint_ror(A, DIST)

Bitwise right rotation (towards less-significant bits, with the
least-significant bit wrapping round to the most-significant bit).
I<DIST> is the distance to rotate, in bits, and must be an integer in
the range [0, natint_bits).

=cut

sub sint_ror($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	$val = sint($val);
	return $val if $dist == 0;
	my $low_val = $val >> $dist;
	use integer;
	return $low_val | ($val << (natint_bits - $dist));
}

sub uint_ror($$) {
	my($val, $dist) = @_;
	$dist = uint($dist);
	croak "shift distance exceeds word size" if $dist >= natint_bits;
	$val = uint($val);
	return $val if $dist == 0;
	return ($val >> $dist) | ($val << (natint_bits - $dist));
}

=back

=head2 Format conversion

These functions convert between the various native integer formats
by reinterpreting the bit patterns used to represent the integers.
The bit pattern remains unchanged; its meaning changes, and so the
numerical value changes.  Perl scalars preserve the numerical value,
rather than just the bit pattern, so from the Perl point of view these
are functions that change numbers into other numbers.

=over

=item nint_bits_as_sint(A)

Converts a native integer of either type to a signed integer, by
reinterpreting the bits.  The most-significant bit (whether a sign bit
or not) becomes a sign bit.

=cut

sub nint_bits_as_sint($) { use integer; nint($_[0]) | 0 }

=item nint_bits_as_uint(A)

Converts a native integer of either type to an unsigned integer, by
reinterpreting the bits.  The most-significant bit (whether a sign bit
or not) becomes an ordinary most-significant bit.

=cut

sub nint_bits_as_uint($) { no integer; nint($_[0]) | 0 }

=item sint_bits_as_uint(A)

Converts a signed integer to an unsigned integer, by reinterpreting
the bits.  The sign bit becomes an ordinary most-significant bit.

=cut

sub sint_bits_as_uint($) { no integer; sint($_[0]) | 0 }

=item uint_bits_as_sint(A)

Converts an unsigned integer to a signed integer, by reinterpreting
the bits.  The most-significant bit becomes a sign bit.

=cut

sub uint_bits_as_sint($) { use integer; uint($_[0]) | 0 }

=back

=head2 Bitwise operations

These functions all operate on the bit patterns representing integers,
completely ignoring the numerical values represented.  They are mostly
not influenced by the word size, in the sense that they will produce
the same numerical result for the same numerical arguments regardless
of word size.  However, a few are affected by the word size: those on
unsigned operands that return a non-zero result if given zero arguments.

Each pair of functions performs exactly the same operations on the bit
sequences.  There inevitably can't be any functions here that operate on
Perl's union of signed and unsigned; you must choose, by which function
you call, which type the result is to be tagged as.

=over

=item sint_not(A)

=item uint_not(A)

Bitwise complement (NOT).

=cut

sub sint_not($) { use integer; ~sint($_[0]) }

sub uint_not($) { no integer; ~uint($_[0]) }

=item sint_and(A, B)

=item uint_and(A, B)

Bitwise conjunction (AND).

=cut

sub sint_and($$) { use integer; sint($_[0]) & sint($_[1]) }

sub uint_and($$) { no integer; uint($_[0]) & uint($_[1]) }

=item sint_nand(A, B)

=item uint_nand(A, B)

Bitwise inverted conjunction (NAND).

=cut

sub sint_nand($$) { use integer; ~(sint($_[0]) & sint($_[1])) }

sub uint_nand($$) { no integer; ~(uint($_[0]) & uint($_[1])) }

=item sint_andn(A, B)

=item uint_andn(A, B)

Bitwise conjunction with inverted argument (A AND (NOT B)).

=cut

sub sint_andn($$) { use integer; sint($_[0]) & ~sint($_[1]) }

sub uint_andn($$) { no integer; uint($_[0]) & ~uint($_[1]) }

=item sint_or(A, B)

=item uint_or(A, B)

Bitwise disjunction (OR).

=cut

sub sint_or($$) { use integer; sint($_[0]) | sint($_[1]) }

sub uint_or($$) { no integer; uint($_[0]) | uint($_[1]) }

=item sint_nor(A, B)

=item uint_nor(A, B)

Bitwise inverted disjunction (NOR).

=cut

sub sint_nor($$) { use integer; ~(sint($_[0]) | sint($_[1])) }

sub uint_nor($$) { no integer; ~(uint($_[0]) | uint($_[1])) }

=item sint_orn(A, B)

=item uint_orn(A, B)

Bitwise disjunction with inverted argument (A OR (NOT B)).

=cut

sub sint_orn($$) { use integer; sint($_[0]) | ~sint($_[1]) }

sub uint_orn($$) { no integer; uint($_[0]) | ~uint($_[1]) }

=item sint_xor(A, B)

=item uint_xor(A, B)

Bitwise symmetric difference (XOR).

=cut

sub sint_xor($$) { use integer; sint($_[0]) ^ sint($_[1]) }

sub uint_xor($$) { no integer; uint($_[0]) ^ uint($_[1]) }

=item sint_nxor(A, B)

=item uint_nxor(A, B)

Bitwise symmetric similarity (NXOR).

=cut

sub sint_nxor($$) { use integer; ~(sint($_[0]) ^ sint($_[1])) }

sub uint_nxor($$) { no integer; ~(uint($_[0]) ^ uint($_[1])) }

=item sint_mux(A, B, C)

=item uint_mux(A, B, C)

Bitwise multiplex.  The output has a bit from B wherever A has a 1 bit,
and a bit from C wherever A has a 0 bit.  That is, the result is (A AND B)
OR ((NOT A) AND C).

=cut

sub sint_mux($$$) {
	my $a = sint($_[0]);
	use integer;
	return ($a & sint($_[1])) | (~$a & sint($_[2]));
}

sub uint_mux($$$) {
	my $a = uint($_[0]);
	no integer;
	return ($a & uint($_[1])) | (~$a & uint($_[2]));
}

=back

=head2 Machine arithmetic

These functions perform arithmetic operations that are inherently
influenced by the word size.  They always produce a well-defined output
if given valid inputs.  There inevitably can't be any functions here
that operate on Perl's union of signed and unsigned; you must choose,
by which function you call, which type the result is to be tagged as.

=over

=item sint_madd(A, B)

=item uint_madd(A, B)

Modular addition.  The result for unsigned addition is (A + B)
mod 2^natint_bits.  The signed version behaves similarly, but with a
different result range.

=cut

sub sint_madd($$) { use integer; sint($_[0]) + sint($_[1]) }

sub uint_madd($$) { 0 | do { use integer; uint($_[0]) + uint($_[1]) } }

=item sint_msub(A, B)

=item uint_msub(A, B)

Modular subtraction.  The result for unsigned subtraction is (A - B)
mod 2^natint_bits.  The signed version behaves similarly, but with a
different result range.

=cut

sub sint_msub($$) { use integer; sint($_[0]) - sint($_[1]) }

sub uint_msub($$) { 0 | do { use integer; uint($_[0]) - uint($_[1]) } }

=item sint_cadd(A, B, CARRY_IN)

=item uint_cadd(A, B, CARRY_IN)

Addition with carry.  Two word arguments (A and B) and an input carry
bit (CARRY_IN, which must have the value 0 or 1) are all added together.
Returns a list of two items: an output carry and an output word (of the
same signedness as the inputs).  Precisely, the output list (CARRY_OUT,
R) is such that CARRY_OUT*2^natint_bits + R = A + B + CARRY_IN.

=cut

sub sint_cadd($$$) {
	my($a, $b, $cin) = map { sint($_) } @_;
	use integer;
	croak "invalid carry" unless $cin == 0 || $cin == 1;
	my $r = $a + $b + $cin;
	my $cout = $b < 0 ? $r > $a ? -1 : 0 : $r < $a ? +1 : 0;
	return ($cout, $r);
}

sub uint_cadd($$$) {
	my($a, $b, $cin) = map { uint($_) } @_;
	use integer;
	croak "invalid carry" unless $cin == 0 || $cin == 1;
	my $r = $a + $b;
	my $cout = ($r ^ min_sint) < ($a ^ min_sint) ? 1 : 0;
	if($cin) {
		$r += 1;
		$cout = 1 if $r == 0;
	}
	return ($cout, do { no integer; 0 | $r });
}

=item sint_csub(A, B, CARRY_IN)

=item uint_csub(A, B, CARRY_IN)

Subtraction with carry (borrow).  The second word argument (B) and
an input carry bit (CARRY_IN, which must have the value 0 or 1) are
subtracted from the first word argument (A).  Returns a list of two
items: an output carry and an output word (of the same signedness as
the inputs).  Precisely, the output list (CARRY_OUT, R) is such that R -
CARRY_OUT*2^natint_bits = A - B - CARRY_IN.

=cut

sub sint_csub($$$) {
	my($a, $b, $cin) = map { sint($_) } @_;
	use integer;
	croak "invalid carry" unless $cin == 0 || $cin == 1;
	my $r = $a - $b - $cin;
	my $cout = $b < 0 ? $r < $a ? -1 : 0 : $r > $a ? +1 : 0;
	return ($cout, $r);
}

sub uint_csub($$$) {
	my($a, $b, $cin) = map { uint($_) } @_;
	use integer;
	croak "invalid carry" unless $cin == 0 || $cin == 1;
	my $r = $a - $b;
	my $cout = ($r ^ min_sint) > ($a ^ min_sint) ? 1 : 0;
	if($cin) {
		$cout = 1 if $r == 0;
		$r -= 1;
	}
	return ($cout, do { no integer; 0 | $r });
}

=item sint_sadd(A, B)

=item uint_sadd(A, B)

Saturating addition.  The result is A + B if that will fit into the result
format, otherwise the minimum or maximum value of the result format is
returned depending on the direction in which the addition overflowed.

=cut

sub sint_sadd($$) {
	my($a, $b) = map { sint($_) } @_;
	use integer;
	my $r = $a + $b;
	if($b < 0) {
		$r = min_sint if $r > $a;
	} else {
		$r = max_sint if $r < $a;
	}
	return $r;
}

sub uint_sadd($$) {
	my($a, $b) = map { uint($_) } @_;
	use integer;
	my $r = $a + $b;
	$r = max_uint if ($r ^ min_sint) < ($a ^ min_sint);
	return do { no integer; 0 | $r };
}

=item sint_ssub(A, B)

=item uint_ssub(A, B)

Saturating subtraction.  The result is A - B if that will fit into the
result format, otherwise the minimum or maximum value of the result
format is returned depending on the direction in which the subtraction
overflowed.

=cut

sub sint_ssub($$) {
	my($a, $b) = map { sint($_) } @_;
	use integer;
	my $r = $a - $b;
	if($b >= 0) {
		$r = min_sint if $r > $a;
	} else {
		$r = max_sint if $r < $a;
	}
	return $r;
}

sub uint_ssub($$) {
	my($a, $b) = map { uint($_) } @_;
	use integer;
	my $r = ($a ^ min_sint) <= ($b ^ min_sint) ? 0 : $a - $b;
	return do { no integer; 0 | $r };
}

=back

=head2 String conversion

=over

=item natint_hex(VALUE)

VALUE must be a native integer value.  The function encodes VALUE in
hexadecimal, returning that representation as a string.  Specifically,
the output is of the form "I<s>B<0x>I<dddd>", where "I<s>" is the sign
and "I<dddd>" is a sequence of hexadecimal digits.

=cut

sub natint_hex($) {
	my $val = nint($_[0]);
	my $sgn = nint_sgn($val);
	$val = nint_abs($val);
	my $digits = "";
	my $i = (natint_bits+3) >> 2;
	for(; $i >= 7; $i -= 7) {
		$digits = sprintf("%07x", $val & 0xfffffff).$digits;
		$val >>= 28;
	}
	for(; $i--; ) {
		$digits = sprintf("%01x", $val & 0xf).$digits;
		$val >>= 4;
	}
	return ($sgn == -1 ? "-" : "+")."0x".$digits;
}

=item hex_natint(STRING)

Generates and returns a native integer value from a string encoding it in
hexadecimal.  Specifically, the input format is "[I<s>][B<0x>]I<dddd>",
where "I<s>" is the sign and "I<dddd>" is a sequence of one or more
hexadecimal digits.  The input is interpreted case insensitively.
If the value given in the string cannot be exactly represented in the
native integer type, the function C<die>s.

The core Perl function C<hex> (see L<perlfunc/hex>) does a similar job
to this function, but differs in several ways.  Principally, C<hex>
doesn't handle negative values, and it gives the wrong answer for values
that don't fit into the native integer type.  In Perl 5.6 it also gives
the wrong answer for values that don't fit into the native floating
point type.  It also doesn't enforce strict syntax on the input string.

=cut

my %hexdigit_value;
{
	use integer;
	$hexdigit_value{chr(ord("0") + $_)} = $_ foreach 0..9;
	$hexdigit_value{chr(ord("a") + $_)} = 10+$_ foreach 0..5;
	$hexdigit_value{chr(ord("A") + $_)} = 10+$_ foreach 0..5;
}

sub hex_natint($) {
	my($str) = @_;
	$str =~ /\A([-+]?)(?:0x)?([0-9a-f]+)\z/i
		or croak "bad syntax for hexadecimal integer value";
	my($sign, $digits) = ($1, $2);
	use integer;
	$digits =~ /\A0*/g;
	return my $zero = 0 if $digits =~ /\G\z/gc;
	$digits =~ /\G(.)/g;
	my $value = $hexdigit_value{$1};
	my $bits_to_go = (length($digits)-pos($digits)) << 2;
	croak "integer value too large"
		if $bits_to_go >= natint_bits ||
			($bits_to_go + 4 > natint_bits &&
				(max_uint >> $bits_to_go) < $value);
	while($digits =~ /\G(.)/g) {
		$value = ($value << 4) | $hexdigit_value{$1};
	}
	if($sign eq "-") {
		$value = -$value;
		croak "integer value too large" if $value >= 0;
		return $value;
	} else {
		no integer;
		return 0 | $value;
	}
}

=back

=head1 BUGS

In Perl 5.6, when a native integer scalar is used in any arithmetic other
than specifically integer arithmetic, it gets partially transformed into
a floating point scalar.  Even if its numerical value can be represented
exactly in floating point, so that floating point arithmetic uses the
correct numerical value, some operations are affected by the floatness.
In particular, the stringification of the scalar doesn't necessarily
represent its exact value if it is tagged as floating point.

Because of this transforming behaviour, if you need to stringify a native
integer it is best to ensure that it doesn't get used in any non-integer
arithmetic first.  If an integer scalar must be used in standard Perl
arithmetic, it may be copied first and the copy operated upon to avoid
causing side effects on the original.  If an integer scalar might have
already been transformed, it can be cleaned by passing it through the
canonicalisation function C<nint>.  The functions in this module all
avoid modifying their arguments, and always return pristine integers.

Perl 5.8+ still internally modifies integer scalars in the same
circumstances, but seems to have corrected all the misbehaviour that
resulted from it.

Also in Perl 5.6, default Perl arithmetic doesn't necessarily work
correctly on native integers.  (This is part of the motivation for
the myriad arithmetic functions in this module.)  Default arithmetic
here is strictly floating point, so if there are native integers that
cannot be exactly represented in floating point then the arithmetic will
approximate the values before operating on them.  Perl 5.8+ attempts to
use native integer operations where possible in its default arithmetic,
but as of Perl 5.8.8 it doesn't always succeed.  For reliable integer
arithmetic, integer operations must still be requested explicitly.

=head1 SEE ALSO

L<Data::Float>,
L<Scalar::Number>,
L<perlnumber(1)>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

Currently maintained by Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2007, 2010, 2015, 2017, 2025
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
