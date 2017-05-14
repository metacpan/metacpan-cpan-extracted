package Carrot::Personality::Reflective::Iterate::Separated_Elements::Tree_Branch::Virtual
# /type class
# //parent_classes
#	[=parent_pkg=]::Tree_Branch
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	separator
#	line
# //returns
{
	my ($this, $separator) = @ARGUMENTS;

	$this->superseded(@ARGUMENTS);
	$this->[ATR_VIRTUAL] = IS_UNDEFINED;

	return;
}

sub virtual
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_VIRTUAL]);
}

sub virtual_path
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return(IS_UNDEFINED) unless (defined($this->[ATR_VIRTUAL]));
	return(join($this->[ATR_SEPARATOR], '', @{$this->[ATR_VIRTUAL]}));
}

sub has_edge
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(defined($_[THIS][ATR_VIRTUAL]));
}

sub edge
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $path = $this->[ATR_PATH];
	return if ($this->[ATR_POSITION] > $#$path);
	$this->[ATR_VIRTUAL] = [
		splice($path, $this->[ATR_POSITION]+1),
		$this->[ATR_BASE_NAME]];
	$this->[ATR_BASE_NAME] = pop($path);
	$this->[ATR_POSITION]--;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.66
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"