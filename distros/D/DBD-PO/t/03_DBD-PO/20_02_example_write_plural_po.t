#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(run_example $FILE_2P $TABLE_2P);
use Test::More;

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 2);

is(
    run_example('02_write_plural_po.pl'),
    q{},
    'run 02_write_plural_po.pl',
);
ok(
    -e $FILE_2P,
    "$TABLE_2P exists",
);