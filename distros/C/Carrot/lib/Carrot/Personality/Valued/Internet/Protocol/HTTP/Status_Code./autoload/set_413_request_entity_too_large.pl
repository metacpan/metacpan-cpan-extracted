package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_413_request_entity_too_large
{
        ${$_[0]} = '413';
        return;
}
return(1);
