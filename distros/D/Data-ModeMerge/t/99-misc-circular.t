#!perl

use strict;
use warnings;
use Test::More tests => 5;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my ($a, $b, $res);

$a = {}; $a->{a} = $a;
$b = {a => 2};
$res = {a => 2};
merge_is($a, $b, $res, "left");

$res = {}; $res->{a} = $res;
merge_is($b, $a, $res, "right");

$a = {i=>1, j=>1}; $a->{a} = $a;
$b = {i=>2, "+j"=>2}; $b->{a} = $b;
$res = {i=>2, j=>3}; $res->{a} = $res;
merge_is($a, $b, $res, "l+r 1");

# i know, this is dubious, maybe $res->{^a}{i} should be 1 and
# $res->{^a}{j} 3. but let's settle on this behaviour for now. merging
# recursive structures is rather weird anyway.
$a = {i=>1, j=>1}; $a->{"^a"} = $a;
$b = {i=>2, "+j"=>2}; $b->{a} = $b;
$res = {i=>2, j=>3}; $res->{"^a"} = $res;
merge_is($a, $b, $res, "l+r 2 (keep)");

# this is impossible for now, because $res->{a} needs immediate
# merging of "+a" and ".a", but due to circularity it won't be
# available until the whole hash is done merged.

$a = {}; $a->{a} = $a;
$b = {}; $b->{".a"} = $b; $b->{"+a"} = $b;
merge_fail($a, $b, "l+r 3 (multiple on right)");

