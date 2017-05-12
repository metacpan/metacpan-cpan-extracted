#!perl

use strict;
use warnings;
use Test::More tests => 12;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

merge_is({i=>1}, {".i"=>3}, {i=>13}, 'int');

merge_is({s=>"tokyo"}, {".s"=>" shibuya"}, {s=>"tokyo shibuya"}, 'str');

merge_is({a=>[1]}, {".a"=>[1,2]}, {a=>[1,1,2]}, 'array 1');
merge_fail({a=>[1]}, {".a"=>2}, 'array 2');
merge_fail({a=>1}, {".a"=>[2]}, 'array 3');
merge_fail({a=>[1]}, {".a"=>{}}, 'array 4');
merge_fail({a=>{}}, {".a"=>[2]}, 'array 5');

merge_is({h=>{a=>1, b=>2}}, {".h"=>{b=>22, c=>3}}, {h=>{a=>1, b=>22, c=>3}}, 'hash 1');
merge_fail({h=>{}}, {".h"=>1}, 'hash 2');
merge_fail({h=>1}, {".h"=>{}}, 'hash 3');
merge_fail({h=>{}}, {".h"=>[]}, 'hash 4');
merge_fail({h=>[]}, {".h"=>{}}, 'hash 5');
