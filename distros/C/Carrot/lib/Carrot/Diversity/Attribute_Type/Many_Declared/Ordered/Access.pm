package Carrot::Diversity::Attribute_Type::Many_Declared::Ordered::Access
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/Many_Declared/Ordered/Access./manual_modularity.pl');
	} #BEGIN

	# the next three are historical left overs
# =--------------------------------------------------------------------------= #

sub _get
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	?
{
	return($_[THIS][$_[SPX_POSITION]]);
}

sub _set
# /type method
# /effect ""
# //parameters
#	position
#	value
# //returns
{
	$_[THIS][$_[SPX_POSITION]] = $_[SPX_VALUE];
	return;
}

sub _get_or_set
# /type method
# /effect ""
# //parameters
#	position
#	value
# //returns
{
	if ($#ARGUMENTS == ADX_FIRST_ELEMENT)
	{
		return($_[THIS][$_[SPX_POSITION]]);
	} else {
		$_[THIS][$_[SPX_POSITION]] = $_[SPX_VALUE];
		return;
	}
}

sub as_list
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(@{$_[THIS]});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.56
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
