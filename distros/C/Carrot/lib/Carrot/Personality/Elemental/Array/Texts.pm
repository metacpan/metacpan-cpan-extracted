package Carrot::Personality::Elemental::Array::Texts
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Array/Texts./manual_modularity.pl');
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
		return(IS_TRUE) if ($_ eq $_[SPX_VALUE]);
	}
	return(IS_FALSE);
}

sub matches_re
# /type method
# /effect ""
# //parameters
#	re
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $re) = @ARGUMENTS;

	for (@$this) {
		return(IS_TRUE) if ($_ =~ m{$re});
	}
	return(IS_FALSE);
}

#FIXME: could become a class of its own
sub matches_as_prefixes
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $value) = @ARGUMENTS;

	foreach (@{$_[THIS]}) {
		return(IS_TRUE) if (substr($_[SPX_VALUE], 0, length($_)) eq $_);
	}
	return(IS_FALSE);
}

sub full_index
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Hash
{
	my $full_index = {};
	my $i = ADX_NO_ELEMENTS;
	foreach my $element (@{$_[THIS]}) {
		$i += 1;
		$full_index->{$element} = $i;
	}
	return($full_index);
}

sub index
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Array_Index
{
	my ($this, $value) = @ARGUMENTS;

	keys(@$this);
	while (my ($i, $element) = each(@$this))
	{
		return($i) if ($value eq $element);
	}
	return(ADX_NO_ELEMENTS);
}

sub index_nearest_lower
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	my ($this, $value) = @ARGUMENTS;

	keys(@$this);
	while (my ($i, $element) = each(@$this))
	{
		return($i) if ($value lt $element);
	}
	return($#$this);
}

sub remove
# /type method
# /effect ""
# //parameters
# //returns
{
	@{$_[THIS]} = (grep(($_ ne $_[SPX_VALUE]), splice(@{$_[THIS]})));
	return;
}

sub all_non_empty
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return([grep(length($_), @{$_[THIS]})]);
}

sub first_non_empty
# /type method
# /effect ""
# //parameters
# //returns
{
	foreach (@{$_[THIS]})
	{
		return($_) if (length($_));
	}
	return;
}

sub last_non_empty
# /type method
# /effect ""
# //parameters
# //returns
{
	foreach (reverse(@{$_[THIS]}))
	{
		return($_) if (length($_));
	}
	return;
}

sub maximum
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return(IS_UNDEFINED) if ($#$this == ADX_NO_ELEMENTS);

	my $max = length($this->[0]);
	foreach (@$this)
	{
		my $l = length($_);
		$max = $l if ($l gt $max);
	}
	return($max);
}

sub minimum
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return(IS_UNDEFINED) if ($#$this == ADX_NO_ELEMENTS);

	my $min = $this->[0];
	foreach (@$this)
	{
		my $l = length($_);
		$min = $l if ($l lt $min);
	}
	return($min);
}

sub first_difference
# /type method
# /effect ""
# //parameters
#	that
# //returns
#	::Personality::Abstract::Array +undefined
{
	my ($this, $that) = @ARGUMENTS;

	if ($#$this != $#$that)
	{
		return([ADX_NO_ELEMENTS, '?', '?']);
	}

	for (my $i = ADX_NO_ELEMENTS; $i <= $#{$_[THIS]}; $i += 1) {
		next if ($this->[$i] eq $that->[$i]);
		return([$i, $this->[$i], $this->[$i]]);
	}
	return(IS_UNDEFINED);
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
