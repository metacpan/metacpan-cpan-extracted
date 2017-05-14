package Carrot::Personality::Valued::Number::Integer
# /type class
# //parent_classes
#	[=component_pkg=]::Number
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $syntax_re = '^(\+|-|)(\d+)$';
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

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.65
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
