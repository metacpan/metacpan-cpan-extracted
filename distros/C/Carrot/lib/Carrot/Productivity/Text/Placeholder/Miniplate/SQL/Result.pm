package Carrot::Productivity::Text::Placeholder::Miniplate::SQL::Result
# /type class
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
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_VALUE] = $this->can('placeholder_value');
	$this->[ATR_PLACEHOLDER_RE] = IS_UNDEFINED;
	$this->[ATR_FIELDS] = [];
	$this->[ATR_SUBJECT] = [];
	return;
}

sub set_placeholder_re
# /type method
# /effect ""
# //parameters
#	placeholder_re
# //returns
{
	$_[THIS][ATR_PLACEHOLDER_RE] = q/$_[SPX_PLACEHOLDER_RE]/;
	return;
}


sub placeholder_value
# /type method
# /effect ""
# //parameters
#	index
# //returns
#	?
{
	return($_[THIS][ATR_SUBJECT][$_[SPX_INDEX]]);
}

sub find_call
# /type method
# /effect ""
# //parameters
#	placeholder
# //returns
#	?
{
	my ($this, $placeholder) = @ARGUMENTS;

	return(IS_UNDEFINED) unless ($placeholder =~ $this->[ATR_PLACEHOLDER_RE]);
	push($this->[ATR_FIELDS], $1);
	return([$this->[ATR_VALUE], [$this, $#{$this->[ATR_FIELDS]}]);
}

sub field_list
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return( sub { return(join(', ', @{$_[THIS][ATR_FIELDS]})) } );
}

sub set_subject
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	$_[THIS][ATR_SUBJECT] = $_[SPX_ROW];
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.47
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"