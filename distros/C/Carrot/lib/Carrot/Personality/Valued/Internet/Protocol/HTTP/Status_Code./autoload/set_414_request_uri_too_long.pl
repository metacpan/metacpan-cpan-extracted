package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_414_request_uri_too_long
{
        ${$_[0]} = '414';
        return;
}
return(1);
