package Carrot::Diversity::Attribute_Type::Many_Declared::Obfuscated::Access
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/Many_Declared/Obfuscated/Access./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub _get
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]{$_[SPX_NAME]});
}

sub _set
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	$_[THIS]{$_[SPX_NAME]} = $_[SPX_VALUE];
	return;
}

sub _get_or_set
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	if ($#ARGUMENTS == ADX_FIRST_ELEMENT)
	{
		return($_[THIS]{$_[SPX_NAME]});
	} else {
		$_[THIS]{$_[SPX_NAME]} = $_[SPX_VALUE];
		return;
	}
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.41
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
