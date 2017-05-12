use Test::More tests => 1;

use warnings;
use strict;

use AutoCurry;

{ 
    package Tsuffix;
    sub t { "@_" };
}

ok( ! Tsuffix->can("t_c") &&
    ! Tsuffix->can("t_X") &&
    do { local $AutoCurry::suffix = "_X";
         AutoCurry::curry_package("Tsuffix") } &&
    ! Tsuffix->can("t_c") &&
    Tsuffix->can("t_X") &&
    Tsuffix::t_X(1)->(2) eq "1 2",
    "can change the function-name suffix"
);
