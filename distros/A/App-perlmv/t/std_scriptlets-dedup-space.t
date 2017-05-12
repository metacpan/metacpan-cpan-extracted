#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use FindBin '$Bin';
require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["a  b"],
            {extra_opt=>"dedup-space"},
            ["a b"], 'dedup-space');

end_testing();
