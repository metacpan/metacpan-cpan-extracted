package Carrot::Personality::Valued::Internet::Protocol::HTTP::Request_Method;
use strict;
use warnings;
sub is_get
{
        return(${$_[0]} eq 'GET');
}
return(1);
