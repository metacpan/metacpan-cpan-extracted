package Carrot::Personality::Elemental::Subroutine::Regular_Expression::Substitute
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Subroutine/Regular_Expression/Substitute./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	value
#	replacement
# //returns
{
	my ($this, $value, $replacement) = @ARGUMENTS;

	$value = quotemeta($value);
	$replacement = quotemeta($replacement);
	$$this = eval "sub { return(\$_[0] =~ s{$value}{$replacement}); }";
	die($EVAL_ERROR) if ($EVAL_ERROR);
	return;
}

sub substitute_in_array
# /type method
# /effect ""
# //parameters
#	array
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $array) = @ARGUMENTS;

	foreach (@$array)
	{
		return(IS_TRUE) if ($this->($_));
	}
	return(IS_FALSE);
}

sub substitute
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return($_[THIS]->($_[SPX_VALUE]));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.123
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"