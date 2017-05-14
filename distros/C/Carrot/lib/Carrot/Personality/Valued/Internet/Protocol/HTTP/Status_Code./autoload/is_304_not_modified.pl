package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_304_not_modified
{
        return(${$_[0]} eq '304');
}
return(1);
