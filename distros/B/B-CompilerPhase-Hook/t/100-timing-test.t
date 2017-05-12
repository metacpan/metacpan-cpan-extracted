#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

BEGIN {
    use_ok('B::CompilerPhase::Hook');
}

BEGIN {
    diag '... pausing to test timer';
}
use Timer;
diag '... timer took '.$Timer::TIME.' seconds';
ok($Timer::TIME > 1, '... the test value is greater than one');

done_testing;
