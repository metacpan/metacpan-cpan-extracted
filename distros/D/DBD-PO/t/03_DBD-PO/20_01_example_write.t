#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(run_example $FILE_2X $TABLE_2X);
use Test::More;

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 2);

is(
    run_example('01_write.pl'),
    q{},
    'run 01_write.pl',
);
ok(
    -e $FILE_2X,
    "$TABLE_2X exists",
);
