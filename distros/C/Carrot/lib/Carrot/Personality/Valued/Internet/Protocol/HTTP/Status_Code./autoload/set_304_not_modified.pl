package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub set_304_not_modified
{
        ${$_[0]} = '304';
        return;
}
return(1);
