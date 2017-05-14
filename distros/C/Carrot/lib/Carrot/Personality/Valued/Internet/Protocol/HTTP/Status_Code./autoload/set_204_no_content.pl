package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_204_no_content
{
        ${$_[0]} = '204';
        return;
}
return(1);
