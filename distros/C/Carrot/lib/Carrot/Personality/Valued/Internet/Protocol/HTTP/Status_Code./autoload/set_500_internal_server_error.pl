package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_500_internal_server_error
{
        ${$_[0]} = '500';
        return;
}
return(1);
