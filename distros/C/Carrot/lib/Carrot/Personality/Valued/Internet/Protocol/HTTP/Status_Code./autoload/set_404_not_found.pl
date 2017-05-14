package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_404_not_found
{
        ${$_[0]} = '404';
        return;
}
return(1);
