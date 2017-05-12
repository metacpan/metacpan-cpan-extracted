#!perl

# minimal and temporary tests, pending real date spectest from Sah

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

# just testing that bool in perl can accept numbers and strings
my @tests = (
    {schema=>["duration"], input=>"1", valid=>1},
    {schema=>["duration"], input=>"foo", valid=>0},
    {schema=>["duration"], input=>"P1DT2H", valid=>1}, # coerce from

    # XXX no tests for min/max/etc for now because we haven't reimplemented coercion for clause/attr value
);

# XXX use test_sah_cases() when it supports js
for my $test (@tests) {
    my $v = gen_validator($test->{schema});
    if ($test->{valid}) {
        ok($v->($test->{input}), $test->{name});
    } else {
        ok(!$v->($test->{input}), $test->{name});
    }
}
done_testing();
