#!perl

use strict;
use warnings;
use Test::More tests => 4;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my $h1 = { 'a'=> 1,  'c'=> 2,  'd'=> 3,  'k'=> 4,  'n'=> 5, 'n2'=> 5,  's'=> 6};
my $h2 = {'+a'=>10, '.c'=>20, '!d'=>30, '^k'=>40, '*n'=>50, 'n2'=>50, '-s'=>60};

mmerge_fail($h1, $h2, {set_prefix=>1 },  "invalid set_prefix 1");
mmerge_fail($h1, $h2, {set_prefix=>[]},  "invalid set_prefix 2");

mmerge_is  ($h1, $h2, {set_prefix=>{}}                     , {a=>11 , c=>220, "^k"=>40, n=>50, n2=>50, s=>-54}, "empty set_prefix");
mmerge_is  ($h1, $h2, {set_prefix=>{ADD=>'.', CONCAT=>'+'}}, {a=>110, c=>22 , "^k"=>40, n=>50, n2=>50, s=>-54}, "set_prefix 1");
