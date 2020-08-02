#!perl

use 5.010001;
use strict;
use warnings;
use Test::More tests => 2;
use Test::Needs 'Lingua::Han::PinYin';
use FindBin '$Bin';
require "$Bin/testlib.pl";

prepare_for_testing();

test_perlmv(["我爱你.txt"], {extra_opt=>"pinyin"}, ["woaini.txt"], 'pinyin');

end_testing();
