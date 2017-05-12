#!perl

use strict;
use warnings;
use Test::More tests => 17;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

mmerge_fail({}, {}, {exclude_merge=> 1}, "error exclude_merge 1");
mmerge_fail({}, {}, {exclude_merge=>{}}, "error exclude_merge 2");
mmerge_fail({}, {}, {exclude_merge_regex=>'('}, "error exclude_merge_regex");

mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_merge=>[]              }, {a=>3, b=>5}, "no exclude_merge");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_merge=>['a','b']       }, {a=>1, b=>1}, "exclude_merge 1");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_merge=>['b']           }, {a=>3, b=>1}, "exclude_merge 2");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_merge_regex=>'^.$'     }, {a=>1, b=>1}, "exclude_merge_regex 1");

mmerge_fail({}, {}, {include_merge=> 1}, "error include_merge 1");
mmerge_fail({}, {}, {include_merge=>{}}, "error include_merge 2");
mmerge_fail({}, {}, {include_merge_regex=>'('}, "error include_merge_regex");

mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_merge=>[]              }, {a=>1, b=>1}, "no include_merge");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_merge=>['a','b']       }, {a=>3, b=>5}, "include_merge 1");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_merge=>['b']           }, {a=>1, b=>5}, "include_merge 2");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_merge_regex=>'^.$'     }, {a=>3, b=>5}, "include_merge_regex 1");

mmerge_is({a=>1, b=>1, "+c"=>1}, {"+a"=>2, "-b"=>3, "+b"=>7, '!c'=>8, d=>9}, {include_merge=>['b','a'], exclude_merge=>['a']       }, {a=>1, 'b'=>5, "+c"=>1}, "include_merge+exclude_merge");
mmerge_is({a=>1, b=>1, "+c"=>1}, {"+a"=>2, "-b"=>3, "+b"=>7, '!c'=>8, d=>9}, {include_merge_regex=>'[ab]', exclude_merge_regex=>'a'}, {a=>1, 'b'=>5, "+c"=>1}, "include_merge_regex+exclude_merge_regex");

mmerge_is({a=>1, b=>1, c=>1, sub=>{a=>1, b=>1, c=>1}, ""=>{include_merge_regex=>''}},
          {a=>2, b=>2, c=>2, sub=>{a=>2, b=>2, c=>2}}, {exclude_merge_regex=>qr/^[ab]$/},
          {a=>1, b=>1, c=>2, sub=>{a=>1, b=>1, c=>2}}, "regex survives cloning");
