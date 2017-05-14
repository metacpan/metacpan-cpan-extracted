package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_405_method_not_allowed
{
        return(${$_[0]} eq '405');
}
return(1);
