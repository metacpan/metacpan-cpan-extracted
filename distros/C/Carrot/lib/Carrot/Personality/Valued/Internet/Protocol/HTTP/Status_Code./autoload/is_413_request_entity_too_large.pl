package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_413_request_entity_too_large
{
        return(${$_[0]} eq '413');
}
return(1);
