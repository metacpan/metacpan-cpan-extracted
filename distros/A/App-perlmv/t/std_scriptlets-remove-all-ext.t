#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 1*2;
use FindBin '$Bin';
require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["a", "b.txt", "c.mp3.mp3"], {extra_opt=>"remove-all-ext"}, ["a", "b", "c"], 'remove-all-ext');

end_testing();
