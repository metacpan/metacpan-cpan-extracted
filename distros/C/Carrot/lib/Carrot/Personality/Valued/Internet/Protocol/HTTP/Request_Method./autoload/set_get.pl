package Carrot::Personality::Valued::Internet::Protocol::HTTP::Request_Method;
use strict;
use warnings;
sub set_get
{
        ${$_[0]} = 'GET';
        return;
}
return(1);
