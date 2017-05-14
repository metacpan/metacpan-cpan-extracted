package Carrot::Personality::Valued::Text::Line::Classified
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/Text/Line/Classified./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub is_empty
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{\A\z}saa);
}

sub is_blank
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{\A\h*\z}saa);
}

sub is_comment_or_blank
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{\A\h*(?:#|\z)}saa);
}

sub is_comment_or_empty
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{\A(#|\z)}saa);
}

sub is_white
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{\A[\000-\037 ]\z}saa);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.48
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
