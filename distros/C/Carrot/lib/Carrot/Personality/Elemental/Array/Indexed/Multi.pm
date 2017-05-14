package Carrot::Personality::Elemental::Array::Indexed::Multi
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Array/Indexed/Multi./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub elements_named
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	return(map($_[THIS][ATR_ARRAY][$_], @{$_[THIS][ATR_INDEX]{$_[SPX_NAME]}}));
}

sub keys
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(\CORE::keys($_[THIS][ATR_INDEX]));
}

sub each
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(CORE::each($_[THIS][ATR_INDEX]));
}

sub push_indexed
# /type method
# /effect ""
# //parameters
#	element
#	iname
# //returns
{
	my ($this) = @ARGUMENTS;

	CORE::push($this->[ATR_ARRAY], $_[SPX_ELEMENT]);
	unless (exists($this->[ATR_INDEX]{$_[SPX_INAME]}))
	{
		$this->[ATR_INDEX]{$_[SPX_INAME]} = [];
	}
	push($this->[ATR_INDEX]{$_[SPX_INAME]}, $#{$this->[ATR_ARRAY]});
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.53
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
