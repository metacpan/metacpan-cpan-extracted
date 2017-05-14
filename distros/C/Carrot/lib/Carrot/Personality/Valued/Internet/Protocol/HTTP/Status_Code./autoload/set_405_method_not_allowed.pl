package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_405_method_not_allowed
{
        ${$_[0]} = '405';
        return;
}
return(1);
