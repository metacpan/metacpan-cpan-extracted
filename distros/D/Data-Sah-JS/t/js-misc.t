#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah::JS qw(gen_validator);
use Nodejs::Util qw(get_nodejs_path);
use Test::More 0.98;

my $node_path = get_nodejs_path();
unless ($node_path) {
    plan skip_all => 'node.js is not available';
}

# check double popping of _sahv_dpath, fixed in 0.42+

my @tests = (
    {
        schema => ["array", {of=>["hash", keys=>{a=>[array=>of=>"any"]}]}],
        input  => [{a=>[]}, {a=>[]}],
        valid  => 1,
    },
);
#test_sah_cases(\@tests, {gen_validator_opts=>{return_type=>"str"}});

# XXX use test_sah_cases() when it supports js
for my $test (@tests) {
    my $v = gen_validator($test->{schema}, {return_type=>"str"});
    my $res = $v->($test->{input});
    if ($test->{valid}) {
        is($res, "", $test->{name}) or diag $res;
    } else {
        isnt($res, "", $test->{name});
    }
}

# XXX test coercion

done_testing();
