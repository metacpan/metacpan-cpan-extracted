package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_402_payment_required
{
        return(${$_[0]} eq '402');
}
return(1);
