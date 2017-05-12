#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(run_example);
use Test::More;

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 1);

is(
    run_example('12_read_using_Locale-TextDomain.pl'),
    q{},
    'run 12_read_using_Locale-TextDomain.pl',
);