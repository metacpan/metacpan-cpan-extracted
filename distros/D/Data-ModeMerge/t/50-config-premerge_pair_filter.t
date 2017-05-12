#!perl

use strict;
use warnings;
use Test::More tests => 8;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

mmerge_ok  ({}, {}, {premerge_pair_filter=>undef}, 'empty');
mmerge_fail({}, {}, {premerge_pair_filter=>1    }, 'invalid 2');
mmerge_fail({}, {}, {premerge_pair_filter=>[]   }, 'invalid 3');
mmerge_fail({}, {}, {premerge_pair_filter=>{}   }, 'invalid 4');

my $c = { premerge_pair_filter=>sub{ uc($_[0]), uc($_[1]) } };
mmerge_is  ({s=>"a"}, {'.s'=>"b"}, $c, {S=>"AB"}, 'sub 1');
mmerge_fail({i=>1, I=>2}, {}, $c, 'conflict 1');

$c = { premerge_pair_filter=>sub{ undef } };
mmerge_is  ({i=>1}, {i=>2}, $c, {}, 'remove 1');

$c = { premerge_pair_filter=>sub{ $_[0], $_[1], uc($_[0]), uc($_[1]) } };
mmerge_is  ({i=>1}, {i=>2}, $c, {i=>2, I=>2}, 'add 1');
