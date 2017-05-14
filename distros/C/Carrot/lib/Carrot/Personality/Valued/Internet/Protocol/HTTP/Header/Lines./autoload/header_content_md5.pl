package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines;

use strict;
use warnings;

sub header_content_md5
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS]->by_name('Content-MD5'));
}

return(1);
