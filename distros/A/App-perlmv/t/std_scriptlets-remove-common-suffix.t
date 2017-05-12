#!perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use FindBin '$Bin';
require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["cupcake.txt", "bake.txt", "brake.txt"], {extra_opt=>"remove-common-suffix"}, ["b.txt", "br.txt", "cupc.txt"], 'remove-common-suffix');

end_testing();
