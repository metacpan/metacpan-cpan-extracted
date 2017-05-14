package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_417_expectation_failed
{
        return(${$_[0]} eq '417');
}
return(1);
