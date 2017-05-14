package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_415_unsupported_media_type
{
        return(${$_[0]} eq '415');
}
return(1);
