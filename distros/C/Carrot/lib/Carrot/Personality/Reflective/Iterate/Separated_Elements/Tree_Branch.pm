package Carrot::Personality::Reflective::Iterate::Separated_Elements::Tree_Branch
# /type class
# //parent_classes
#	[=parent_pkg=]::Flat
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->superseded(@ARGUMENTS);
	$this->[ATR_LEAF_NAME] = IS_UNDEFINED;

	if ($#{$this->[ATR_ELEMENTS]} > ADX_NO_ELEMENTS)
	{
		$this->[ATR_POSITION] -= 1;
		$this->[ATR_LEAF_NAME] = pop($this->[ATR_ELEMENTS]);
	}

	return;
}

sub iterated_path
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return('') if ($this->[ATR_POSITION] == -1);
	my $remaining = join($this->[ATR_SEPARATOR],
		'',
		(@{$this->[ATR_ELEMENTS]})[0..$this->[ATR_POSITION]]);
	return($remaining);
}

sub remaining_path
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $path = $this->[ATR_ELEMENTS];
	return('') if ($this->[ATR_POSITION] <= $#$path);
	my $remaining = join($this->[ATR_SEPARATOR],
		'',
		(@$path)[$this->[ATR_POSITION]..$#$path]);
	return($remaining);
}

sub leaf_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_LEAF_NAME]);
}

sub iterate
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	if ($this->[ATR_POSITION] == $#{$this->[ATR_ELEMENTS]})
	{
		$this->[ATR_POSITION] = ADX_LAST_ELEMENT;
		return(IS_UNDEFINED);
	}
	return($this->[ATR_ELEMENTS][++$this->[ATR_POSITION]]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.73
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"