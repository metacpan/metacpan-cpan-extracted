#! perl

#
# 04-env-num.t
#
# Tests for the 'num' constant type, where values
# are forced to numeric values, or it will croak
# if the value is non-numeric
#

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    $ENV{'PI'}           = 3.141592654;
    $ENV{'ONE'}          = 1;
    $ENV{'MINUS_ONE'}    = -1;
    $ENV{'TWO_THIRDS'}   = 2/3;
    $ENV{'FORTY_TWO'}    = 'forty two';
}

use Constant::FromGlobal { num => 1, env => 1 },
                         qw/ PI ONE MINUS_ONE TWO_THIRDS /;

ok(ONE == 1,                             "ONE should have value 1");
ok(MINUS_ONE == -1,                      "MINUS_ONE should have value -1");
ok(PI > 3.13 && PI < 3.15,               "PI should have roughly the value of pi");
ok(TWO_THIRDS > 0.6 && TWO_THIRDS < 0.7, "TWO_THIRDS should be between 0.6 and 0.7");

eval {
    Constant::FromGlobal->import({ num => 1, env => 1}, 'FORTY_TWO');
};
ok($@ && $@ =~ /does not look like a number/,
   "'forty two' should result in croak, since it doesn't look like a number");

done_testing;
