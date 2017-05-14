package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_404_not_found
{
        return(${$_[0]} eq '404');
}
return(1);
