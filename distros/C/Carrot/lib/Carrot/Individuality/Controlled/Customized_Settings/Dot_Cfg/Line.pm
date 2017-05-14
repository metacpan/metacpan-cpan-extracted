package Carrot::Individuality::Controlled::Customized_Settings::Dot_Cfg::Line
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# //parent_classes
#	::Personality::Valued::Text::Line::Classified
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub is_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^name(?:\t| {4})(\w+)\h*$});
}

sub is_section
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^\[(.*)\]$});
}

sub is_separator
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^-{8}\h*$});
}

sub is_source_class
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^source(?:\t|   )(.+)$});
}

sub is_data
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^(?:\t| {8})(.*)$});
}

sub is_quoted_data
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^'(?:\t| {7})(.*)$});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.85
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
