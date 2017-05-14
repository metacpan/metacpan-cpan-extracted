package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_414_request_uri_too_long
{
        return(${$_[0]} eq '414');
}
return(1);
