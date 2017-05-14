package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_412_precondition_failed
{
        return(${$_[0]} eq '412');
}
return(1);
