package Carrot::Personality::Valued::Number::Floating_Point
# /type class
# //parent_classes
#	[=component_pkg=]::Number
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $syntax_re = '^(\+|-)?\d+\.\d+$';

# =--------------------------------------------------------------------------= #

sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[SPX_VALUE] =~ m{$syntax_re}so);
}

sub canonify_dot_zero
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	unless (${$_[THIS]} =~ m{\.\d+$}s) 
	{
		${$_[THIS]} .= '.0';
	}
	${$_[THIS]} =~ s{^(\+|-|)\.}{${1}0.}s;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.50
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
