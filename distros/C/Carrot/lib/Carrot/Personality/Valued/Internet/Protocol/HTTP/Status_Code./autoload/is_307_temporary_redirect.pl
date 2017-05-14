package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_307_temporary_redirect
{
        return(${$_[0]} eq '307');
}
return(1);
