#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Setup qw/:silent/; # strict, warnings, Test::More, Carp etc.

use_ok $_ for qw(
    Data::Dumper::Interp
);

done_testing;

