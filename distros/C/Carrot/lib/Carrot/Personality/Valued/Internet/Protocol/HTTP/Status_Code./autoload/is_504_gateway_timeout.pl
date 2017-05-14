package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_504_gateway_timeout
{
        return(${$_[0]} eq '504');
}
return(1);
