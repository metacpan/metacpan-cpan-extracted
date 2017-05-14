package Carrot::Modularity::Object::Universal;

use strict;
use warnings;

sub can_all_of
# /type method
# /effect ""
# //parameters N
#	method_names
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);

	foreach my $name (@ARGUMENTS)
	{
		next if ($this->can($name));
		return(IS_FALSE);
	}
	return(IS_TRUE);
}

return(1);
