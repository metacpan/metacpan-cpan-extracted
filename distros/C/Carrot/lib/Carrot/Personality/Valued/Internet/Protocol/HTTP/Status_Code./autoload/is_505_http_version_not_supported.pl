package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_505_http_version_not_supported
{
        return(${$_[0]} eq '505');
}
return(1);
