package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_424_failed_dependency
{
        return(${$_[0]} eq '424');
}
return(1);
