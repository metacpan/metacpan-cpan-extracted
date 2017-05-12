#!perl

use strict;
use warnings;
use Test::More tests => 70;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

merge_fail({''=>1 }, {}, 'invalid type 1');
merge_fail({''=>[]}, {}, 'invalid type 2');
merge_fail({}, {''=>1 }, 'invalid type 3');
merge_fail({}, {''=>[]}, 'invalid type 4');
merge_fail({''=>{}}, {''=>1 }, 'invalid type 5');
merge_fail({''=>{}}, {''=>[]}, 'invalid type 6');

merge_fail ({''=>{x=>1}}, {''=>{}}, 'unknown config');
merge_fail ({''=>{wanted_path=>["x"]}}, {''=>{}}, 'allowed in merger config only: wanted_path');
merge_fail ({''=>{options_key=>"x"}}, {''=>{}}, 'allowed in merger config only: options_key');
merge_fail ({''=>{allow_override=>["x"]}}, {''=>{}}, 'allowed in merger config only: allow_override');
merge_fail ({''=>{disallow_override=>["x"]}}, {''=>{}}, 'allowed in merger config only: disallow_override');

mmerge_fail({''=>{allow_create_hash=>0 }}, {''=>{}}, {disallow_override=>qr/^allow_create/}, 'disallow_override 1');
mmerge_ok  ({''=>{allow_destroy_hash=>0}}, {''=>{}}, {disallow_override=>qr/^allow_create/}, 'disallow_override 2');

mmerge_fail({''=>{allow_destroy_hash=>0}}, {''=>{}}, {allow_override=>qr/^allow_create/}, 'allow_override 1');
mmerge_ok  ({''=>{allow_create_hash=>0 }}, {''=>{}}, {allow_override=>qr/^allow_create/}, 'allow_override 2');

mmerge_fail({''=>{allow_destroy_array=>0}}, {''=>{}}, {allow_override=>qr/^allow_create/, disallow_override=>qr/hash/}, 'allow_override+disallow_override 1');
mmerge_fail({''=>{allow_create_hash=>0  }}, {''=>{}}, {allow_override=>qr/^allow_create/, disallow_override=>qr/hash/}, 'allow_override+disallow_override 2');
mmerge_ok  ({''=>{allow_create_array=>0 }}, {''=>{}}, {allow_override=>qr/^allow_create/, disallow_override=>qr/hash/}, 'allow_override+disallow_override 3');

merge_fail({a=>1, b=>2, ''=>{exclude_merge_regex=>'(a' }}, {a=>10, b=>20}, 'invalid value 1');
merge_is  ({a=>1, b=>2, ''=>{exclude_merge_regex=>'(a)'}}, {a=>10, b=>20}, {a=>1, b=>20}, 'invalid value 2');

merge_is({a=>1, b=>2, ''=>{  exclude_merge_regex =>'a'}}, {a=>10, b=>20, ''=>{  exclude_merge_regex =>'b'}}, {a=>10, b=>2 }, 'merging 1');
merge_is({a=>1, b=>2, ''=>{"^exclude_merge_regex"=>'a'}}, {a=>10, b=>20, ''=>{  exclude_merge_regex =>'b'}}, {a=>1 , b=>20}, 'merging 2');
merge_is({a=>1, b=>2, ''=>{ "exclude_merge_regex"=>'a'}}, {a=>10, b=>20, ''=>{"!exclude_merge_regex"=>'b'}}, {a=>10, b=>20}, 'merging 3');

merge_fail({''=>{'+exclude_merge'=>'a'}},
           {''=>{'.exclude_merge'=>'a'}}, 'merging failed');

mmerge_is({a=>1, b=>2, ''=>{exclude_merge_regex =>'a'}          }, {a=>10, b=>20}, undef               , {a=>1 , b=>20       }, 'change ok 1');
mmerge_is({a=>1, b=>2, ''=>3, 'foo'=>{exclude_merge_regex =>'a'}}, {a=>10, b=>20}, {options_key=>'foo'}, {a=>1 , b=>20, ''=>3}, 'change ok 2');
mmerge_is({a=>1, b=>2, ''=>{exclude_merge_regex =>'a'}          }, {a=>10, b=>20}, {options_key=>undef}, {a=>10, b=>20, ''=>{exclude_merge_regex=>'a'}}, 'disable ok');

merge_ok({''=>{}}, {''=>{}}, 'valid 1');

my $h1 = { 'a'=> 1,  'c'=> 2,  'd'=> 3,  'k'=> 4,  'n'=> 5, 'n2'=> 5,  's'=> 6};
my $h2 = {'+a'=>10, '.c'=>20, '!d'=>30, '^k'=>40, '*n'=>50, 'n2'=>50, '-s'=>60};
my $hm = {a=>11, c=>220, "^k"=>40, n=>50, n2=>50, s=>-54};

for (
    {l=>$h1, ok=>{}, r=>$h2, res=>$hm, desc=>"none"},
    {l=>{a=>{a2=>1}}, ok=>{recurse_hash=>0}, r=>{a=>{".a2"=>2}}, res=>{a=>{".a2"=>2}}, desc=>"recurse_hash"},
    {l=>{a=>[{a2=>1}]}, ok=>{recurse_array=>1}, r=>{a=>[{b2=>2}]}, res=>{a=>[{a2=>1, b2=>2}]}, desc=>'recursive array'},
    {l=>$h1, ok=>{parse_prefix=>0}, r=>$h2, res=>{%$h1, %$h2}, desc=>"parse_prefix"},
    {l=>$h1, ok=>{default_mode=>"KEEP"}, r=>$h2, res=>$h1, desc=>"default_mode"},
    {l=>$h1, ok=>{disable_modes=>[qw/ADD/]}, r=>$h2, res=>{%$hm, a=>1, '+a'=>10}, desc=>"disable_modes"},
    {l=>{a=>1 }, ok=>{allow_create_array=>0 }, r=>{a=>[]}, fail=>1, desc=>"allow_create_array"},
    {l=>{a=>1 }, ok=>{allow_create_hash=>0  }, r=>{a=>{}}, fail=>1, desc=>"allow_create_hash"},
    {l=>{a=>[]}, ok=>{allow_destroy_array=>0}, r=>{a=>1 }, fail=>1, desc=>"allow_destroy_array"},
    {l=>{a=>{}}, ok=>{allow_destroy_hash=>0 }, r=>{a=>1 }, fail=>1, desc=>"allow_destroy_hash"},
    {l=>$h1, ok=>{exclude_parse=>['+a']}     , r=>$h2, res=>{%$hm, a=>1, '+a'=>10}, desc=>"exclude_parse"},
    {l=>$h1, ok=>{include_parse=>['!d','^k']}, r=>$h2, res=>{%$hm, a=>1, '+a'=>10, c=>2, '.c'=>20, n=>5, '*n'=>50, n2=>50, s=>6, '-s'=>60}, desc=>"include_parse"},
    {l=>$h1, ok=>{exclude_parse_regex=>'a'}  , r=>$h2, res=>{%$hm, a=>1, '+a'=>10}, desc=>"exclude_parse_regex"},
    {l=>$h1, ok=>{include_parse_regex=>'d|k'}, r=>$h2, res=>{%$hm, a=>1, '+a'=>10, c=>2, '.c'=>20, n=>5, '*n'=>50, n2=>50, s=>6, '-s'=>60}, desc=>"include_parse_regex"},
    {l=>$h1, ok=>{exclude_merge=>['a']}      , r=>$h2, res=>{%$hm, a=>1}, desc=>"exclude_merge"},
    {l=>$h1, ok=>{include_merge=>[qw/d k/]}  , r=>$h2, res=>{%$hm, a=>1, c=>2, n=>5, n2=>5, s=>6}, desc=>"include_merge"},
    {l=>$h1, ok=>{exclude_merge_regex=>'a'}  , r=>$h2, res=>{%$hm, a=>1}, desc=>"exclude_merge_regex"},
    {l=>$h1, ok=>{include_merge_regex=>'d|k'}, r=>$h2, res=>{%$hm, a=>1, c=>2, n=>5, n2=>5, s=>6}, desc=>"include_merge_regex"},
    {l=>$h1, ok=>{set_prefix=>{ADD=>'.',CONCAT=>'+'}}, r=>$h2, res=>{%$hm, a=>110, c=>22}, desc=>"set_prefix"},
    {l=>{"^a"=>1}, ok=>{readd_prefix=>0}, r=>{a=>2}, res=>{a=>1}, desc=>"readd_prefix"},
) {
    # we test putting options key on the left hash, as well as on the
    # right hash
    if ($_->{fail}) {
        merge_fail({ %{$_->{l}}, ''=>$_->{ok} }, $_->{r}, "okl $_->{desc}");
        merge_fail($_->{l}, { %{$_->{r}}, ''=>$_->{ok} }, "okr $_->{desc}");
    } else {
        merge_is({ %{$_->{l}}, ''=>$_->{ok} }, $_->{r}, $_->{res}, "okl $_->{desc}");
        merge_is($_->{l}, { %{$_->{r}}, ''=>$_->{ok} }, $_->{res}, "okr $_->{desc}");
    }
}

merge_is({h=>{  i =>1, ""=>{parse_prefix=>1}},   i =>1, h2=>{  i =>1}, ''=>{parse_prefix=>0}},
         {h=>{"+i"=>2                       }, "+i"=>2, h2=>{"+i"=>2}                       },
         {h=>{  i =>3}, i=>1, "+i"=>2, h2=>{i=>1, "+i"=>2}},
         'ok works for subhashes, and can be overriden by subhash');

merge_is({i=>1   , ""=>{PARSE_PREFIX=>0, ""=>{}}},
         {"+i"=>2, ""=>{                 ""=>{premerge_pair_filter=>sub{lc($_[0]), $_[1]} }}},
         {i=>1, "+i"=>2},
         'ok inside ok');
