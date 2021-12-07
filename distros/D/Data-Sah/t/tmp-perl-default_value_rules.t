#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah 'gen_validator';

my $sch = ["str", "x.perl.default_value_rules"=>[ ["Str::repeat"=>{str=>"foo", n=>3}] ]];
my $v   = gen_validator($sch, {return_type=>"str_errmsg+val"});

is_deeply($v->("a"), ['',"a"]);
is_deeply($v->(undef), ['',"foofoofoo"]);

done_testing;
