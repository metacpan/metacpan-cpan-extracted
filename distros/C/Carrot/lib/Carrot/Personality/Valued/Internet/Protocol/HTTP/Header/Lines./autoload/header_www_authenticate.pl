package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_www_authenticate
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('WWW-Authenticate'));
}

return(1);
