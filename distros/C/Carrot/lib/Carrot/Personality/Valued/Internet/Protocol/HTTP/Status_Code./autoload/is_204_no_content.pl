package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_204_no_content
{
        return(${$_[0]} eq '204');
}
return(1);
