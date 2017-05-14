package Carrot::Personality::Valued::Discrete::Yes_No
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(($_[SPX_VALUE] eq 'yes') or ($_[SPX_VALUE] eq 'no'));
}

sub is_yes
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} eq 'yes');
}

sub is_no
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} eq 'no');
}

sub logical_value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(((${$_[THIS]} eq 'yes') ? IS_TRUE : IS_FALSE))
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.57
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
