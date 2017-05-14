package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_301_moved_permanently
{
        return(${$_[0]} eq '301');
}
return(1);
