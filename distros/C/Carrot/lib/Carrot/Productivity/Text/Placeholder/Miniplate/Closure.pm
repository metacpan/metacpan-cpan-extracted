package Carrot::Productivity::Text::Placeholder::Miniplate::Closure
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	$_[THIS][ATR_PLACEHOLDERS] = {};
	return;
}

sub find_call
# /type method
# /effect ""
# //parameters
#	placeholder
# //returns
#	?
{
	return(exists($_[THIS][ATR_PLACEHOLDERS]{$_[SPX_PLACEHOLDER]})
		? $_[THIS][ATR_PLACEHOLDERS]{$_[SPX_PLACEHOLDER]}
		: undef);
}

sub add_placeholder
# /type method
# /effect ""
# //parameters
#	name
#	closure
#	placeholders
# //returns
{
	my ($this, $name, $closure) = splice(\@ARGUMENTS, 0, 3);

	$this->[ATR_PLACEHOLDERS]{$name} = [$closure, [@ARGUMENTS]];

	return;
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