package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_422_unprocessable_entity
{
        return(${$_[0]} eq '422');
}
return(1);
