package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_503_service_unavailable
{
        return(${$_[0]} eq '503');
}
return(1);
