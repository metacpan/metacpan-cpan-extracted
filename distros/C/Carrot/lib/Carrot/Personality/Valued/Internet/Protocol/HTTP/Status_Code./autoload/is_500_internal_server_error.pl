package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_500_internal_server_error
{
        return(${$_[0]} eq '500');
}
return(1);
