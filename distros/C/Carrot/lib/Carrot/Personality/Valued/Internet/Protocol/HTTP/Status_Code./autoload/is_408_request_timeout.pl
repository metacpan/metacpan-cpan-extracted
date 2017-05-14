package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_408_request_timeout
{
        return(${$_[0]} eq '408');
}
return(1);
