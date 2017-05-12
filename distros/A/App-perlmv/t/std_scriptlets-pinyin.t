#!perl

use 5.010;
use strict;
use warnings;

BEGIN {
    eval { require Lingua::Han::PinYin };
    if ($@) {
        require Test::More;
        Test::More::plan(skip_all => "Lingua::Han::PinYin not available");
    }
}

use Test::More tests => 2;
use FindBin '$Bin';
require "$Bin/testlib.pl";
prepare_for_testing();

test_perlmv(["我爱你.txt"], {extra_opt=>"pinyin"}, ["woaini.txt"], 'pinyin');

end_testing();
