package Carrot::Personality::Elemental::Array::Text_or_Number
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Array/Text_or_Number./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub append_if_distinct
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(IS_FALSE) if ($_[THIS]->contains($_[SPX_VALUE]));
	push(@{$_[THIS]}, $_[SPX_VALUE]);
	return(IS_TRUE);
}

sub propend_if_distinct
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(IS_FALSE) if ($_[THIS]->contains($_[SPX_VALUE]));
	unshift(@{$_[THIS]}, $_[SPX_VALUE]);
	return(IS_TRUE);
}

sub insert_sorted
# /type method
# /effect ""
# /parameters *
# //returns
{
	splice(@{$_[THIS]}, $_[THIS]->index_nearest_lower(@ARGUMENTS), 0, $_[SPX_VALUE]);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.80
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
