package Carrot::Personality::Elemental::Hash::Enumerated
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Hash/Enumerated./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	bless([{}, []], $_[THIS]);
}

sub elements
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ARRAY]);
}

sub element_at
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	::Personality::Abstract::Text
{
	return($_[THIS][ATR_INDEX]{$_[THIS][ATR_ARRAY][$_[SPX_POSITION]]});
}

sub ref_element_at
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	::Personality::Abstract::Text
{
	return(\$_[THIS][ATR_INDEX]{$_[THIS][ATR_ARRAY][$_[SPX_POSITION]]});
}

sub element_named
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Text
{
	return($_[THIS][ATR_INDEX]{$_[SPX_NAME]});
}

sub keys
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return([\CORE::keys($_[THIS][ATR_INDEX])]);
}

sub each
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(CORE::each($_[THIS][ATR_INDEX]));
}

sub add
# /type method
# /effect ""
# //parameters
#	name
#	element
# //returns
{
	$_[THIS][ATR_INDEX]{$_[SPX_NAME]} = $_[SPX_ELEMENT];
	return;
}

sub add_indexed
# /type method
# /effect ""
# //parameters
#	name
#	element
# //returns
{
	my ($this) = @ARGUMENTS;

	unless (exists($this->[ATR_INDEX]{$_[SPX_NAME]}))
	{
		CORE::push($this->[ATR_ARRAY], $_[SPX_ELEMENT]);
	}
	$this->[ATR_INDEX]{$_[SPX_NAME]} = $_[SPX_ELEMENT];
	return;
}

sub lock
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	Internals::SvREADONLY(@{$this->[ATR_ARRAY]}, 1);
	Internals::hv_clear_placeholders(%{$this->[ATR_INDEX]});
	Internals::SvREADONLY(%{$this->[ATR_INDEX]}, 1);
	return;
}

sub unlock
# /type method
# /effect ""
# //parameters
# //returns
{
	Internals::SvREADONLY(@{$_[THIS][ATR_ARRAY]}, 0);
	Internals::SvREADONLY(%{$_[THIS][ATR_INDEX]}, 0);
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
