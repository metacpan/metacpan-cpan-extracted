package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_502_bad_gateway
{
        return(${$_[0]} eq '502');
}
return(1);
