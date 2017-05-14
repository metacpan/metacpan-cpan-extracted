package Carrot::Personality::Valued::Date::Timestamp
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/Date/Timestamp./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub is_newer_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[SPX_VALUE] > ${$_[THIS]});
}

sub is_newer
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THAT]} > ${$_[THIS]});
}

sub is_older_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[SPX_VALUE] < ${$_[THIS]});
}

sub is_older
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THAT]} < ${$_[THIS]});
}

sub is_same_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[SPX_VALUE] == ${$_[THIS]});
}

sub is_same
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THAT]} == ${$_[THIS]});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.37
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
