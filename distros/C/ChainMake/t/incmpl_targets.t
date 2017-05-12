#!/usr/bin/perl

# this tests incomplete target definitions

use strict;
use Test::More tests => 22;
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

ok(unlink_timestamps(),'clean timestamps');

ok(!(target 'A', (
)), "declare empty target A should fail");


ok((target '', (
    handler => sub {
        have_made('noname');
        1;
    }
)), "declare anonymous target should fail");


ok((target 'B', (
    handler => sub {
        have_made('B');
        1;
    }
)), "declare target B: only handler");

note "B should always be executed";
my_ok('B','B','B');
my_ok('B','B','B');


ok((target 'C', (
    requirements => ['B'],
)), "declare target C: only requirements");

note "C: requirements should always be checked/made";
my_ok('C','B','B->C');
my_ok('C','B','B->C');

ok(!(target 'D', (
    timestamps   => 'once',
)), "declare target D with only timestamps should fail");

ok(!(target 'E2', (
    requirements => ['B'],
    timestamps   => 'once',
)), "declare target E with timestamps and requirements should fail");

ok(!(target 'F', (
    insistent => 1,
)), "declare target F with only insistent should fail");

ok(!(target 'G', (
    idddssdf => ['jdsjd'],
)), "declare target G with only garbage should fail");

ok(!(target 'H', (
    requirements => 'B',
)), "declare target H: wrong requirements should fail");

ok(!(target 'I', (
    requirements => ['B'],
    timestamps   => 'always',
)), "declare target I: wrong timestamps should fail");

ok(!(target 'J', (
    requirements => ['B'],
    handler => {a=>1},
)), "declare target J: wrong handler should fail");

ok(!(target 'K', (
    requirements => ['B'],
    insistent => [],
)), "declare target K: wrong insistent should fail");

SKIP: {
    skip "because the type check is not for real", 1 if 1;
    ok(!(target 'N', (
        requirements => ['B'],
        insistent => 'yes',
    )), "declare target N: wrong insistent should fail");

};

ok(unlink_timestamps(),'clean timestamps');
