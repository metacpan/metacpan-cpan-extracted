package Carrot::Productivity::Text::Placeholder::Miniplate::Counter
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
	my ($this) = @ARGUMENTS;

	$this->[ATR_COUNTER] = 1;

	return;
}

sub reset
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_COUNTER] = 1;
	return;
}

sub increase
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_COUNTER]++;
	return;
}

sub syp_counter
# /type method
# /effect ""
# //parameters
#	format
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $format) = @ARGUMENTS;

	unless (defined($format))
	{
		return($this->[ATR_COUNTER]);

	} elsif ($format eq 'a')
	{
		return(chr(95+$this->[ATR_COUNTER]));

	} elsif ($format eq 'A')
	{
		return(chr(63+$this->[ATR_COUNTER]));

	} else {
		return(sprintf($format, $this->[ATR_COUNTER]));

	}
}

sub syp_counter_alphabetically
# /type method
# /effect ""
# //parameters
#	format
# //returns
#	?
{
	return(chr(95+$_[THIS][ATR_COUNTER]))
}

sub syp_counter_ALPHABETICALLY
# /type method
# /effect ""
# //parameters
#	format
# //returns
#	?
{
	return(chr(63+$_[THIS][ATR_COUNTER]))
}

sub syp_counter_hexadecimal
# /type method
# /effect ""
# //parameters
#	format
# //returns
#	?
{
	# Ooops, the hex builtin is actually an unhex, so sprintf is required
	return(sprintf('%x', $_[THIS][ATR_COUNTER]))
}

sub syp_counter_HEXADECIMAL
# /type method
# /effect ""
# //parameters
#	format
# //returns
#	?
{
	return(sprintf('%X', $_[THIS][ATR_COUNTER]))
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.46
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"