package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_407_proxy_authentication_required
{
        return(${$_[0]} eq '407');
}
return(1);
