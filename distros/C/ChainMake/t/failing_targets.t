#!/usr/bin/perl

# this tests incomplete target definitions

use strict;
use Test::More tests => 11;
use File::Touch;

BEGIN {
    use_ok('ChainMake::Tester',":all");
    use_ok('ChainMake::Functions',":all")
};

ok(configure(
    verbose => 0,
    silent  => 1,
    timestamps_file => 'test-failing.stamps',
),'configure');

unlink ('B.test');
ok(unlink_timestamps(),'clean timestamps');

ok((target 'A', (
    timestamps   => 'once',
    handler => sub {
        have_made('A');
        0;
    }
)), "failing target A");

note "A should always be executed";
my_nok('A','A','A');
my_nok('A','A','A');


ok((target 'B', (
    timestamps   => ['B.test'],
    handler => sub {
        touch 'B.test';
        have_made('B');
        0;
    }
)), "failing target B; creating a file");

note "B should always be executed";
my_nok('B','B','B');
my_nok('B','B','B');


ok(unlink_timestamps(),'clean timestamps');
unlink ('B.test');
