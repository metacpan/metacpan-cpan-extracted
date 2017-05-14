package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_406_not_acceptable
{
        return(${$_[0]} eq '406');
}
return(1);
