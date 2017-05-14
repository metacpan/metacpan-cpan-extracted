package Carrot::Personality::Elemental::Array::Numbers
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Array/Numbers./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub contains
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	for (@{$_[THIS]}) {
		next if ($_ == $_[SPX_VALUE]);
		return(IS_TRUE);
	}
	return(IS_FALSE);
}

sub index
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Number
{
	my ($this, $value) = @ARGUMENTS;

	keys($this);
	while (my ($i, $element) = each(@$this)) 
	{
		return($i) if ($value == $element);
	}
	return(ADX_NO_ELEMENTS);
}

sub index_nearest_lower
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Number
{
	my ($this, $value) = @ARGUMENTS;

	keys($this);
	while (my ($i, $element) = each(@$this)) 
	{
		return($i) if ($value < $element);
	}
	return($#$this);
}

sub insert_sorted
# /type method
# /effect ""
# /parameters *
# //returns
{
	splice(@{$_[THIS]},
		$_[THIS]->index_nearest_lower(@ARGUMENTS),
		0,
		$_[SPX_VALUE]);
	return;
}

sub remove
# /type method
# /effect ""
# //parameters
# //returns
{
	@{$_[THIS]} = (grep(($_ != $_[SPX_VALUE]), splice(@{$_[THIS]})));
	return;
}

sub sum
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	# 0 in contrast to NULL in SQL; 0 is the neutral element of addition
	my $sum = 0;
	foreach (@{$_[THIS]}) 
	{
	    $sum += $_;
	}
	return($sum);
}

sub maximum
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number +undefined
{
	my ($this) = @ARGUMENTS;

	# there is no neutral element in this context
	return(IS_UNDEFINED) if ($#$this == ADX_NO_ELEMENTS);

	my $max = $this->[ADX_FIRST_ELEMENT];
	foreach my $element (@$this) 
	{
	    $max = $element if ($element > $max);
	}
	return($max);
}

sub minimum
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Number || IS_UNDEFINED
{
	my ($this) = @ARGUMENTS;

	return(IS_UNDEFINED) if ($#$this == ADX_NO_ELEMENTS);

	my $min = $this->[ADX_FIRST_ELEMENT];
	foreach my $element (@$this) 
	{
	    $min = $element if ($element < $min);
	}
	return($min);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.89
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
