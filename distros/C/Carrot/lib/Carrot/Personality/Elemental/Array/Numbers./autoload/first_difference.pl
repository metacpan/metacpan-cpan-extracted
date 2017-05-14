package Carrot::Personality::Elemental::Array::Numbers;
use strict;
use warnings;

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
		next if ($this->[$i] == $that->[$i]);
		return([$i, $this->[$i], $this->[$i]]);
	}
	return(IS_UNDEFINED);
}

return(1);
