package Carrot::Personality::Elemental::Scalar::Numeric
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Scalar/Numeric./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub absolute
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(abs(${$_[THIS]}));
}

sub add_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} += $_[SPX_VALUE];
	return;
}

sub add_to_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	$_[SPX_VALUE] += ${$_[THIS]};
	return;
}

sub add
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} += ${$_[THAT]};
	return;
}

sub added_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} + $_[SPX_VALUE]);
}

sub added
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} + ${$_[THAT]});
}

#sub arc_tangent_xy
## method (<this>, <x>, <y>) public
#{
#	...
#};

sub is_between
# /type method
# /effect ""
# //parameters
#	lower
#	upper
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} > $_[SPX_LOWER])
		and (${$_[THIS]} < $_[SPX_UPPER]));
}

sub is_within
# /type method
# /effect ""
# //parameters
#	lower
#	upper
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} >= $_[SPX_LOWER])
		and (${$_[THIS]} <= $_[SPX_UPPER]));
}

sub bit_and_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} &= $_[SPX_VALUE];
	return;
}

sub bit_and_on_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	$_[SPX_VALUE] &= ${$_[THIS]};
	return;
}

sub bit_and
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} &= ${$_[THAT]};
	return;
}

sub bit_anded_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} & $_[SPX_VALUE]);
}

sub bit_anded
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} & ${$_[THAT]});
}

sub bit_or_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} |= $_[SPX_VALUE];
	return;
}

sub bit_or_to_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	$_[SPX_VALUE] |= ${$_[THIS]};
	return;
}

sub bit_or
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} |= ${$_[THAT]};
	return;
}

sub bit_ored_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} | $_[SPX_VALUE]);
}

sub bit_ored
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} | ${$_[THAT]});
}

sub bit_xor_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} ^= $_[SPX_VALUE];
	return;
}

sub bit_xor_to_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	$_[SPX_VALUE] ^= ${$_[THIS]};
	return;
}

sub bit_xor
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} ^= ${$_[THAT]};
	return;
}

sub bit_xored_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} ^ $_[SPX_VALUE]);
}

sub bit_xored
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} ^ ${$_[THAT]});
}

sub bit_negate
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = ~ ${$_[THIS]};
	return;
}

sub bit_negated
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(~ ${$_[THIS]});
}

sub bit_shift_left_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} <<= $_[SPX_VALUE];
	return;
}

sub bit_shift_left
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} <<= ${$_[THAT]};
	return;
}

sub bit_shifted_left_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} << $_[SPX_VALUE]);
}

sub bit_shifted_left
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} << ${$_[THAT]});
}

sub bit_shift_right_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} >>= $_[SPX_VALUE];
	return;
}

sub bit_shift_right
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} >>= ${$_[THAT]};
	return;
}

sub bit_shifted_right_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} >> $_[SPX_VALUE]);
}

sub bit_shifted_right
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} >> ${$_[THAT]});
}

sub ascii_character
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(chr(${$_[THIS]}));
}

sub cosine
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(cos(${$_[THIS]}));
}

sub difference_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} - $_[SPX_VALUE]);
}

sub difference
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} - ${$_[THAT]});
}

sub divided_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} / $_[SPX_VALUE]);
}

sub divided
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} / ${$_[THAT]});
}

sub divide_by_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} /= $_[SPX_VALUE];
	return;
}

sub divide_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	$_[SPX_VALUE] /= ${$_[THIS]};
	return;
}

sub divide
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} /= ${$_[THAT]};
	return;
}

sub is_equal_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} == $_[SPX_VALUE]));
}

sub is_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} == ${$_[THAT]}));
}

sub exponential
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(exp(${$_[THIS]}));
}

sub hexadecimal_to_decimal
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(hex(${$_[THIS]}));
}

sub decimal_to_hexadecimal
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(sprintf('%X', ${$_[THIS]}));
}

sub is_greater_value
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} > $_[SPX_VALUE]));
}

sub is_greater
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} > ${$_[THAT]}));
}

sub is_greater_equal_value
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} >= $_[SPX_VALUE]));
}

sub is_greater_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} >= ${$_[THAT]}));
}

sub fractionless
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(int(${$_[THIS]}));
}

sub is_lesser_value
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} < $_[SPX_VALUE]));
}

sub is_lesser
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} < ${$_[THAT]}));
}

sub is_lesser_equal_value
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} <= $_[SPX_VALUE]));
}

sub is_lesser_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} <= ${$_[THAT]}));
}

sub logarithm
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(log(${$_[THIS]}));
}

sub multiplied_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} * $_[SPX_VALUE]);
}

sub multiplied
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} * ${$_[THAT]});
}

sub multiply_by_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} *= $_[SPX_VALUE];
	return;
}

sub multiply_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	$_[SPX_VALUE] *= ${$_[THIS]};
	return;
}

sub multiply
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} *= ${$_[THAT]};
	return;
}

sub modulo_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} % $_[SPX_VALUE]);
}

sub modulo
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} % ${$_[THAT]});
}

sub octal_to_decimal
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(oct(${$_[THIS]}));
}

sub decimal_to_octal
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(sprintf('%O', ${$_[THIS]}));
}

sub power_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} ** $_[SPX_VALUE]);
}

sub power
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} ** ${$_[THAT]});
}

sub sine
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(sin(${$_[THIS]}));
}

#sub sort_direction
## /type method
## /effect ""
## //parameters
##	<that>           ::Personality::Abstract::Instance
## //returns
##	::Personality::Abstract::Number
#{
#	return((${$_[THIS]} <=> ${$_[THAT]}));
#}

sub square_root
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(sqrt(${$_[THIS]}));
}

sub subtract_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} -= $_[SPX_VALUE];
	return;
}

sub subtract_from_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	$_[SPX_VALUE] -= ${$_[THIS]};
	return;
}

sub subtract
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} -= ${$_[THAT]};
	return;
}

#sub sum
## /type method
## /effect ""
## //parameters
##	<value> ::Personality::Abstract::Number
## //returns
##	::Personality::Abstract::Number
#{
#	return(${$_[THIS]} + $_[SPX_VALUE]);
#};

sub is_in_set
# /type method
# /effect ""
# //parameters
#	element  +multiple
# //returns
#	::Personality::Abstract::Boolean
{
	my $this = shift(\@ARGUMENTS);

	foreach (@ARGUMENTS)
	{
		return(IS_TRUE) if ($$this == $_);
	}
	return(IS_FALSE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.107
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
