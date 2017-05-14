package Carrot::Personality::Valued::Internet::Protocol::HTTP::Request_Method;
use strict;
use warnings;
sub set_head
{
        ${$_[0]} = 'HEAD';
        return;
}
return(1);
