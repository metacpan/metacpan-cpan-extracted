package Carrot::Personality::Valued::Internet::Protocol::HTTP::Request_Method;
use strict;
use warnings;
sub is_post
{
        return(${$_[0]} eq 'POST');
}
return(1);
