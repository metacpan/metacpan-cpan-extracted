package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_101_switching_protocols
{
        return(${$_[0]} eq '101');
}
return(1);
