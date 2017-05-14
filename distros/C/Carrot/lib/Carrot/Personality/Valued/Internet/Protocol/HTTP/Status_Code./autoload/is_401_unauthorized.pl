package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_401_unauthorized
{
        return(${$_[0]} eq '401');
}
return(1);
