package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code;
use strict;
use warnings;
sub is_416_requested_range_not_satisfiable
{
        return(${$_[0]} eq '416');
}
return(1);
