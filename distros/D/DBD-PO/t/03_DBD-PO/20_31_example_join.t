#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(run_example $DROP_TABLE $PATH);
use Test::More;

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 7);

is(
    run_example('31_join.pl'),
    q{},
    'run 31_join.pl',
);

my @files = map {"$PATH/$_.po"} qw(de ru de_to_ru);

# check files
for (@files) {
    ok(
        -e $_,
        "$_ exists",
    );
}

# drop table
SKIP: {
    skip('delete file', 1)
        if ! $DROP_TABLE;

    for (@files) {
        unlink $_;
        ok(
            ! -e $_,
            "$_ not exists",
        );
    }
}