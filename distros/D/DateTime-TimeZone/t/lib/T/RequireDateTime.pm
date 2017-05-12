package T::RequireDateTime;

use strict;
use warnings;

use Test::More 0.96;

my $dt_version = '0.1501';

sub import {
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    return if eval "use DateTime $dt_version; 1;" && !$@;

    plan skip_all =>
        "Cannot run tests before DateTime.pm $dt_version is installed.";
}

1;
