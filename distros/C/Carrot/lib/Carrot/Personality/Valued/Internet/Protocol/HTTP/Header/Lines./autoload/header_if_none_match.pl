package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_if_none_match
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('If-None-Match'));
}

return(1);
