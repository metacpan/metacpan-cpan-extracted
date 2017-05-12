#!perl

use strict;
use warnings;
use Test::More tests => 13;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

merge_is({i=>1}, {"-i"=>3}, {i=>-2}, 'int');

merge_is({a=>[1,2,3]}, {"-a"=>[2]}, {a=>[1,3]}, 'array 1a');
merge_is({a=>[{a=>1},[2,3],3]}, {"-a"=>[{a=>2},[2,3],3]}, {a=>[{a=>1}]}, 'array 1b');
merge_fail({a=>[1]}, {"-a"=>2}, 'array 2');
merge_fail({a=>1}, {"-a"=>[2]}, 'array 3');
merge_fail({a=>[1]}, {"-a"=>{}}, 'array 4');
merge_fail({a=>{}}, {"-a"=>[2]}, 'array 5');

merge_is({h=>{a=>1}}, {"-h"=>{a=>undef}}, {h=>{}}, 'hash 1');
merge_is({h=>{a=>1, b=>1}}, {"-h"=>{a=>2, "+b"=>2, c=>2}}, {h=>{b=>3}}, 'hash 1b');
merge_fail({h=>{}}, {"-h"=>1}, 'hash 2');
merge_fail({h=>1}, {"-h"=>{}}, 'hash 3');
merge_fail({h=>{}}, {"-h"=>[]}, 'hash 4');
merge_fail({h=>[]}, {"-h"=>{}}, 'hash 5');

