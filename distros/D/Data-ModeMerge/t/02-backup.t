#!perl

use strict;
use warnings;
use Test::More tests => 4;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

is_deeply(mode_merge({a=>1, b=>1}, {b=>2})->{backup}, {b=>1}, 'backup 1a');
is_deeply(mode_merge({a=>1, b=>1}, {b=>2}, {recurse_hash=>0})->{backup}, undef, 'backup 1b');
is_deeply(mode_merge([5, 6, 7], [8, 9])->{backup}, undef, 'backup 2a');
is_deeply(mode_merge([5, 6, 7], [8, 9], {recurse_array=>1})->{backup}, [5, 6], 'backup 2b');
