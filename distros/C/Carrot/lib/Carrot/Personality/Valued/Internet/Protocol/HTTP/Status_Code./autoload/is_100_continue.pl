package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_100_continue
{
        return(${$_[0]} eq '100');
}
return(1);
