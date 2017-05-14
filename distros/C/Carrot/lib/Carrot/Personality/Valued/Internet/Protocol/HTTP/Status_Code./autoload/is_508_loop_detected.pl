package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_508_loop_detected
{
        return(${$_[0]} eq '508');
}
return(1);
