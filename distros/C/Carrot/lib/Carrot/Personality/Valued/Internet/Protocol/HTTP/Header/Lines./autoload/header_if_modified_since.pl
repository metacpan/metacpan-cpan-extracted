package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_if_modified_since
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('If-Modified-Since'));
}

return(1);
