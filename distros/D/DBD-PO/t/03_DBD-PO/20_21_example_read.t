#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(run_example $DROP_TABLE $FILE_2X $TABLE_2X);
use Test::More;

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 2);

is(
    run_example('21_read.pl'),
    q{},
    'run 21_read.pl',
);

# drop table
SKIP: {
    skip('delete file', 1)
        if ! $DROP_TABLE;

    unlink $FILE_2X;
    ok(
        ! -e $FILE_2X,
        "$TABLE_2X not exists",
    );
}
