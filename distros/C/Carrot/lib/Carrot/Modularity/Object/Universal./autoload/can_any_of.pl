package Carrot::Modularity::Object::Universal;

use strict;
use warnings;

sub can_any_of
# /type method
# /effect ""
# //parameters N
#	method_name
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);

	foreach my $name (@ARGUMENTS)
	{
		next unless ($this->can($name));
		return(IS_TRUE);
	}
	return(IS_FALSE);
}

return(1);
