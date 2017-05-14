package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_408_request_timeout
{
        ${$_[0]} = '408';
        return;
}
return(1);
