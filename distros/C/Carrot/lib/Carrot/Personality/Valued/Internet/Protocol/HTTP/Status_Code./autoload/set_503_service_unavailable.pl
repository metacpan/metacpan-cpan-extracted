package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_503_service_unavailable
{
        ${$_[0]} = '503';
        return;
}
return(1);
