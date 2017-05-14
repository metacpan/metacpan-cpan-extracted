package Carrot::Personality::Reflective::Iterate::Separated_Elements::Flat
# /type class
# //parent_classes
#	::Personality::Reflective::Iterate::Array::Forward
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	separator
#	line
# //returns
{
	my ($this, $separator) = @ARGUMENTS;

	$this->superseded(
		[split($separator, $_[SPX_LINE], PKY_SPLIT_RETURN_FULL_TRAIL)]);
	$this->[ATR_SEPARATOR] = $separator;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.64
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"