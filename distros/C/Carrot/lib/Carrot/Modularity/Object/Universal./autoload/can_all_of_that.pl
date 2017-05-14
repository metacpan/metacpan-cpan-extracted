package Carrot::Modularity::Object::Universal;

use strict;
use warnings;

sub can_all_of_that
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	my ($this, $that) = @ARGUMENTS;

	return(($this->isa($that)
		or $this->can_all_of($that->registered_method_names))
		? IS_TRUE
		: IS_FALSE);
}

return(1);
