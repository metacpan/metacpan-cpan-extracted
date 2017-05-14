package Carrot::Individuality::Controlled::Customized_Settings::Definition::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	structure
# //returns
{
	my ($this, $structure) = @ARGUMENTS;

	$this->[ATR_STRUCTURE] = $structure;
	$this->[ATR_SOURCE] = IS_UNDEFINED;

	return;
}

sub start_default
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	$_[THIS][ATR_SOURCE] = $_[SPX_SOURCE];
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.62
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"