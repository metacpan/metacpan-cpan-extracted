package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_100_continue
{
        ${$_[0]} = '100';
        return;
}
return(1);
