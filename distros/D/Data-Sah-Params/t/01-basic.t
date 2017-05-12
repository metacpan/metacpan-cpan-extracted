#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Params qw(compile Optional Named Slurpy);
use Test::Exception;
use Test::More 0.98;

subtest "positional" => sub {
    my $v = compile("int*", ["array", of=>"int*"]);
    dies_ok { $v->() } "missing required param 1";
    dies_ok { $v->(1) } "missing required param 2";
    dies_ok { $v->(undef, []) } "param 1 cannot be undef";
    lives_ok { $v->(1, undef) } "param 2 can be undef";
    dies_ok { $v->("x", undef) } "failed validation for param 1";
    dies_ok { $v->(1, "x") } "failed validation for param 2";
    dies_ok { $v->(1, [1,"x"]) } "failed validation for param 2 #2";
    dies_ok { $v->(1, [], undef) } "too many params";
};

subtest "Optional" => sub {
    my $v = compile("int*", Optional "int*");
    lives_ok { $v->(1) } "optional param can be unspecified";
    lives_ok { $v->(1, 2) };
    dies_ok { $v->(1, undef) } "validation of optional param still performed";
};

subtest "Slurpy" => sub {
    my $v = compile("int*", Slurpy ["array", of=>"int*"]);
    lives_ok { $v->(1) };
    lives_ok { $v->(1, 2,3,4) };
    dies_ok { $v->(1, 2,3,"x") };
};

subtest "Named" => sub {
    dies_ok { compile("int*", Named(a=>"int*")) } "cannot be mixed #1";
    dies_ok { compile(Named(a=>"int*"), "int*") } "cannot be mixed #2";
    dies_ok { compile(Named()) } "empty pairs not allowed";
    dies_ok { compile(Named("a")) } "odd elements in pairs not allowed";
    my $v = compile(Named a=>"int*", b=>"int", c=>Optional "int");
    lives_ok { $v->(a=>1, b=>undef) };
    lives_ok { $v->(a=>1, b=>undef, c=>undef) };
    dies_ok { $v->(a=>1) };
    dies_ok { $v->(b=>1) };
    dies_ok { $v->(a=>1, b=>1, c=>"x") };
};

subtest "opt:want_source=1" => sub {
    like(compile({want_source=>1}, "int*"), qr/sub/);
};

done_testing;
