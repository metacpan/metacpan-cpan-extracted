use strict;
use Test::More;
use utf8;

use Acme::EvaTitlenize;

my $expect_1 = <<'END';
使
徒, 襲来
END

is(Acme::EvaTitlenize::lower_left('使徒', ', 襲来') . "\n", $expect_1, 'lower_left');

my $expect_2 = <<'END';
決戦, 第3新
         東
         京
         市
END

is(Acme::EvaTitlenize::upper_right('決戦, 第3', '新東京市') . "\n", $expect_2, 'upper_right');

done_testing;

