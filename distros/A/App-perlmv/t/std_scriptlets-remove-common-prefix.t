#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use FindBin '$Bin';
require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["steven", "sterk", "stoop"], {extra_opt=>"remove-common-prefix"}, ["erk", "even", "oop"], 'remove-common-prefix');

end_testing();
