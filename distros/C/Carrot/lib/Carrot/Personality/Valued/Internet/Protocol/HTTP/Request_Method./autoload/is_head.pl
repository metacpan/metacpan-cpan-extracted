package Carrot::Personality::Valued::Internet::Protocol::HTTP::Request_Method;
use strict;
use warnings;
sub is_head
{
        return(${$_[0]} eq 'HEAD');
}
return(1);
