#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_TestCommon ':silent', qw/bug/; # Test::More etc.

use_ok $_ for qw(
    Data::Dumper::Interp
);

done_testing;

