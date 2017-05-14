package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_content_type
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('Content-Type'));
}

return(1);
