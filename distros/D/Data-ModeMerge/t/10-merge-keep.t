#!perl

use strict;
use warnings;
use Test::More tests => 4;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

merge_is({'^a'=>1, '^b'=>2,     '^c'=>3, '^c2'=>3, '^d'=>4, '^e'=>5, '^f'=>6, g=>7},
         {  a =>9, '!b'=>undef, '+c'=>9, '.c2'=>9, '-d'=>9, '*e'=>9, '^f'=>9, g=>9},
         {'^a'=>1, '^b'=>2,     '^c'=>3, '^c2'=>3, '^d'=>4, '^e'=>5, '^f'=>6, g=>9}, 'hash 1');

merge_is({"^a"=>1}, {a=>2, "+a"=>3, ".a"=>4, "-a"=>5, "!a"=>6, "^a"=>7}, {"^a"=>1}, 'protect multiple');

my $dm;
$dm = Data::ModeMerge->new();
$dm->config->default_mode('KEEP');
merge_is({a=>1,       c=>{d=>1},   d =>1,   e =>1,   f =>[],      g =>1, },
         {a=>2, b=>2, c=>{d=>2}, '!d'=>0, '+e'=>2, '+f'=>[1,2], '^g'=>2, },
         {a=>1, b=>2, c=>{d=>1},   d =>1,   e =>1,   f =>[],      g =>1, },
         'default merge mode KEEP 1', $dm);
merge_is(1,
         [2],
         1,
         'default merge mode KEEP 2', $dm);
