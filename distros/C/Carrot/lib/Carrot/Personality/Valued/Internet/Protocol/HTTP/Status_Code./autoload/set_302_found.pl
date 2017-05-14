package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_302_found
{
        ${$_[0]} = '302';
        return;
}
return(1);
