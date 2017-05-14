package Carrot::Personality::Reflective::Iterate::Array::Cursor
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Reflective/Iterate/Array/Cursor./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	elements
#	cursor
# //returns
{
	my ($this, $elements, $cursor) = @ARGUMENTS;

	$this->SUPER::attribute_construction($elements);
	$this->[ATR_CURSOR] = $cursor;

	return;
}

sub _re_constructor
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
#	cursor
# //returns
{
	my ($this, $cursor) = @ARGUMENTS;

	$this->[ATR_CURSOR] = $cursor;

	return;
}

sub reset
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->SUPER::reset;
	$_[THIS][ATR_CURSOR]->undefine;
	return;
}

sub advance
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $rv = $this->SUPER::advance;
	if ($rv)
	{
		$this->[ATR_CURSOR]->assign_value(
			$this->[ATR_ELEMENTS][$this->[ATR_POSITION]]);
	}
	return($rv);
}

sub current_element
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_CURSOR]);
}

sub current_index_n_element
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_POSITION], $_[THIS][ATR_CURSOR]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.112
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"