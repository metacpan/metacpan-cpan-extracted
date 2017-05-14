package Carrot::Individuality::Controlled::Customized_Settings::Dot_Cdf::Line
# /type class
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
	return(${$_[THIS]} =~ m{^name(?:\t| {4})(\w+) *$});
}

sub is_some_class
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^(flat|source|list|element|table|row|column)(?:\t| +)(.*)$});
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

sub is_data
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^(?:\t| {8})\h*(.*?)\h*$});
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

sub is_anchor
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^anchor(?:\t| {1})([\w\:]+::)$});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.84
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
