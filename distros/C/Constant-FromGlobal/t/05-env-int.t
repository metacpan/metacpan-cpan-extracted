#! perl

#
# 05-env-int.t
#
# tests for the 'int' coercion / constraint, which ensures that
# constants have an integer value
#

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    $ENV{'ONE'}          = 1;
    $ENV{'ZERO'}         = 0;
    $ENV{'MINUS_ONE'}    = -1;
    $ENV{'FORTY_TWO'}    = 42;
    $ENV{'PI'}           = 3.141592654;
}

use Constant::FromGlobal { int => 1, env => 1 },
                         qw/ ONE ZERO MINUS_ONE FORTY_TWO /;

ok(ONE == 1,                             "ONE should have value 1");
ok(ZERO == 0,                            "ZERO should have value 0");
ok(MINUS_ONE == -1,                      "MINUS_ONE should have value -1");
ok(FORTY_TWO == 42,                      "FORTY_TWO should have value 42");

eval {
    Constant::FromGlobal->import({ int => 1, env => 1}, 'PI');
};
ok($@ && $@ =~ /does not look like an integer/,
   "'3.141592654' should result in croak, since it doesn't look like an integer");

done_testing;
