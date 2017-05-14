package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_403_forbidden
{
        return(${$_[0]} eq '403');
}
return(1);
