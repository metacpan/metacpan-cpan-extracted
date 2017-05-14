package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_transfer_encoding
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('Transfer-Encoding'));
}

return(1);
