#!perl

use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my $mm = Data::ModeMerge->new;

dies_ok(sub {$mm->add_prefix([], 'ADD')}, 'invalid 1');
dies_ok(sub {$mm->add_prefix({}, 'ADD')}, 'invalid 2');

is($mm->add_prefix( 'a', 'ADD'),  '+a', 'ADD 1');
is($mm->add_prefix('+a', 'ADD'), '++a', 'ADD 2');
is($mm->add_prefix('.a', 'ADD'), '+.a', 'ADD 3');

is($mm->add_prefix( 'a', 'CONCAT'),  '.a', 'CONCAT 1');
is($mm->add_prefix('.a', 'CONCAT'), '..a', 'CONCAT 2');
is($mm->add_prefix('*a', 'CONCAT'), '.*a', 'CONCAT 3');

is($mm->add_prefix( 'a', 'DELETE'),  '!a', 'DELETE 1');
is($mm->add_prefix('!a', 'DELETE'), '!!a', 'DELETE 2');
is($mm->add_prefix('*a', 'DELETE'), '!*a', 'DELETE 3');

is($mm->add_prefix( 'a', 'KEEP'),  '^a', 'KEEP 1');
is($mm->add_prefix('^a', 'KEEP'), '^^a', 'KEEP 2');
is($mm->add_prefix('*a', 'KEEP'), '^*a', 'KEEP 3');

is($mm->add_prefix( 'a', 'NORMAL'),  '*a', 'NORMAL 1');
is($mm->add_prefix('*a', 'NORMAL'), '**a', 'NORMAL 2');
is($mm->add_prefix('-a', 'NORMAL'), '*-a', 'NORMAL 3');

is($mm->add_prefix( 'a', 'SUBTRACT'),  '-a', 'SUBTRACT 1');
is($mm->add_prefix('-a', 'SUBTRACT'), '--a', 'SUBTRACT 2');
is($mm->add_prefix('*a', 'SUBTRACT'), '-*a', 'SUBTRACT 3');
