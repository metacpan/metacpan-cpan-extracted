#!perl

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(run_example $FILE_2M $TABLE_2M);
use Test::More;

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 2);

is(
    run_example('03_write_plural_mo.pl'),
    q{},
    'run 03_write_plural_mo.pl',
);
ok(
    -e $FILE_2M,
    "$TABLE_2M exists",
);