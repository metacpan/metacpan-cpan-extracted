use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Acme::Keyakizaka46
    Acme::Keyakizaka46::Base
    Acme::Keyakizaka46::NijikaIshimori
); # memberのモジュールは自動生成なので1人だけ見ればよい

done_testing;

