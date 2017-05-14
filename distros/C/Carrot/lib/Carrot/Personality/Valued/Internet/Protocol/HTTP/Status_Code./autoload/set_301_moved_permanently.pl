package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_301_moved_permanently
{
        ${$_[0]} = '301';
        return;
}
return(1);
