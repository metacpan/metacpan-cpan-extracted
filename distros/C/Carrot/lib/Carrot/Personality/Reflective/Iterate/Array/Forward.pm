package Carrot::Personality::Reflective::Iterate::Array::Forward
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Reflective/Iterate/Array/Forward./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	array
# //returns
{
	$_[THIS][ATR_ELEMENTS] = $_[SPX_ARRAY];
	$_[THIS][ATR_POSITION] = ADX_NO_ELEMENTS;

	return;
}

sub reset
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_POSITION] = ADX_NO_ELEMENTS;
	return;
}

sub advance
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this) = @ARGUMENTS;

	return(IS_FALSE) if ($this->[ATR_POSITION] >= $#{$this->[ATR_ELEMENTS]});
	$this->[ATR_POSITION] += 1;
	return(IS_TRUE);
}

sub current_element
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ELEMENTS][$_[THIS][ATR_POSITION]]);
}

sub current_index
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_POSITION]);
}

sub highest_index
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($#{$_[THIS][ATR_ELEMENTS]});
}

sub current_index_n_element
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return($this->[ATR_POSITION],
		$this->[ATR_ELEMENTS][$this->[ATR_POSITION]]);
}

sub first_element
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ELEMENTS][ADX_FIRST_ELEMENT]);
}

sub last_element
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ELEMENTS][ADX_FIRST_ELEMENT]);
}

sub all_elements
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ELEMENTS]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.78
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"