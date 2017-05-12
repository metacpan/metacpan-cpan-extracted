#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use Bit::Compare;

# 55c999179ad889e9924010d5e14b8ab8789148f2a3b51ce588108230122e1558
# 598155f69858acbd80489c4ea3480ddd6fbc05b42bb51cc58294ae84f2a03154
# 55453536094899f100c218d4b949c1a8ee90099021368c6d2b13825032021910


is(bitcompare(
   'aa', 'ab'
), 1, "bitcompare works");

is(bitcompare(
    '773e2df0a02a319ec34a0b71d54029111da90838cbc20ecd3d2d4e18c25a3025',
    '47182cf0802a11dec24a3b75d5042d310ca90838c9d20ecc3d610e98560a3645'
), 36, "Nilsimsatest works");

is(Bit::Compare->bitcompare(
   'aa', 'ab'
), 1, "bitcompare works, also as a class function");
