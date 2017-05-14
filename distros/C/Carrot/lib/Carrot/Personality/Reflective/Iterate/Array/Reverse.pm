package Carrot::Personality::Reflective::Iterate::Array::Reverse
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Reflective/Iterate/Array/Reverse./manual_modularity.pl');
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
	$_[THIS][ATR_POSITION] = scalar(@{$_[SPX_ARRAY]});

	return;
}

sub reset
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_POSITION] = scalar(@{$_[THIS][ATR_ELEMENTS]});
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

	return(IS_FALSE) if ($this->[ATR_POSITION] == ADX_NO_ELEMENTS);
	$this->[ATR_POSITION] -= 1;
	return(IS_TRUE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.74
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"