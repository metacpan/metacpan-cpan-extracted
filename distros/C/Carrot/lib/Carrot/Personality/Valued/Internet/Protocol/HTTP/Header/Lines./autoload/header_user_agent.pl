package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_user_agent
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('User-Agent'));
}

return(1);
