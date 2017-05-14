package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_206_partial_content
{
        return(${$_[0]} eq '206');
}
return(1);
