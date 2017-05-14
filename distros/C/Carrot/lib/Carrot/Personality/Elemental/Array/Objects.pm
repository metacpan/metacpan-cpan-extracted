package Carrot::Personality::Elemental::Array::Objects
# /type class
# /attribute_type ::One_Anonymous::Array
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Array/Objects./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub method_results
# /type method
# /effect ""
# //parameters
#	method
#	*
# //returns
#	?
{
    my ($this, $method) = splice(\@ARGUMENTS, 0, 2);

    my $results = [];
    push($results, $_->$method(@ARGUMENTS)) foreach (@$this);
    return($results);
}

sub method_summed_results
# /type method
# /effect ""
# //parameters
#	method
#	*
# //returns
#	?
{
    my ($this, $method) = splice(\@ARGUMENTS, 0, 2);

    my $result = 0;
    $result += $_->$method(@ARGUMENTS) foreach (@$this);
    return($result);
}

sub method_reduced_results
# /type method
# /effect ""
# //parameters
#	method
# //returns
#	?
{
    my ($this, $method) = (shift(), shift());

    my $result = IS_UNDEFINED;
    $result = $_->$method($result, @ARGUMENTS) foreach (@$this);
    return($result);
}

sub contains
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my $class = Scalar::Util::blessed($_[SPX_VALUE]);
	for (@{$_[THIS]}) {
		return(IS_TRUE) if (Scalar::Util::blessed($_) eq $class);
	}
	return(IS_FALSE);
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

	my $class = Scalar::Util::blessed($value);
	keys($this);
	while (my ($i, $element) = each(@$this)) 
	{
		return($i) if (Scalar::Util::blessed($element) eq $class);
	}
	return(ADX_NO_ELEMENTS);
}

sub remove
# /type method
# /effect ""
# //parameters
# //returns
{
	my $class = Scalar::Util::blessed($_[SPX_VALUE]);
	@{$_[THIS]} = (grep((Scalar::Util::blessed($_) ne $class),
		splice(@{$_[THIS]})));
	return;
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
		next if (Scalar::Util::blessed($this->[$i]) ==
			Scalar::Util::blessed($that->[$i]));
		return([$i, $this->[$i], $this->[$i]]);
	}
	return(IS_UNDEFINED);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.95
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
