package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_retry_after
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('Retry-After'));
}

return(1);
