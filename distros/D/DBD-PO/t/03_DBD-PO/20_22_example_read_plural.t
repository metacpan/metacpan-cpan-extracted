#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(run_example $DROP_TABLE $FILE_2P $TABLE_2P);
use Test::More;

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 2);

is(
    run_example('22_read_plural.pl'),
    q{},
    'run 22_read_plural.pl',
);

# drop table
SKIP: {
    skip('delete file', 1)
        if ! $DROP_TABLE;

    unlink $FILE_2P;
    ok(
        ! -e $FILE_2P,
        "$TABLE_2P not exists",
    );
}