package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_400_bad_request
{
        ${$_[0]} = '400';
        return;
}
return(1);
