package Carrot::Personality::Elemental::Array::Instances
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Array/Instances./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub contains
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my $class = Scalar::Util::refaddr($_[SPX_VALUE]);
	foreach (@{$_[THIS]})
	{
		return(IS_TRUE) if (Scalar::Util::refaddr($_) == $class);
	}
	return(IS_FALSE);
}

sub subset_can
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Raw::Subroutine
{
	return([grep($_->can($_[SPX_VALUE]), @{$_[THIS]})]);
}

sub subset_isa
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return([grep($_->isa($_[SPX_VALUE]), @{$_[THIS]})]);
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

	my $class = Scalar::Util::refaddr($value);
	keys($this);
	while (my ($i, $element) = each(@$this)) 
	{
		return($i) if (Scalar::Util::refaddr($element) == $class);
	}
	return(ADX_NO_ELEMENTS);
}

sub remove
# /type method
# /effect ""
# //parameters
# //returns
{
	my $class = Scalar::Util::refaddr($_[SPX_VALUE]);
	@{$_[THIS]} = (grep((Scalar::Util::refaddr($_) != $class),
		splice(@{$_[THIS]})));
	return;
}

sub remove_failed_method
# /type method
# /effect ""
# //parameters
#	method
# //returns
{
	my ($this, $method) = @ARGUMENTS;

	@$this = (grep($_->$method, @$this));
	return;
}

sub remove_successful_method
# /type method
# /effect ""
# //parameters
#	method
# //returns
{
	my ($this, $method) = @ARGUMENTS;

	@$this = (grep(!$_->$method, @$this));
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.100
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
