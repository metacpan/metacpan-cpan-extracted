package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_400_bad_request
{
        return(${$_[0]} eq '400');
}
return(1);
