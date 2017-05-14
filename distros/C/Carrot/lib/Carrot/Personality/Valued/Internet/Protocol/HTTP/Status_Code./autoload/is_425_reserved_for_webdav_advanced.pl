package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_425_reserved_for_webdav_advanced
{
        return(${$_[0]} eq '425');
}
return(1);
