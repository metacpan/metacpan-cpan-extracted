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
    {schema=>["date"], input=>"2014-01-25", valid=>1},
    # {schema=>["date"], input=>"2014-02-30", valid=>0}, # node.js cheats by not really validating diligently
    {schema=>["date"], input=>"2014-02-32", valid=>0},
    {schema=>["date"], input=>"2014-05-04T16:19:00Z", valid=>1}, # XXX timezone not set to UTC
    {schema=>["date"], input=>"2014-05-04T16:19:70Z", valid=>0},
    {schema=>["date"], input=>"x", valid=>0},
    {schema=>["date"], input=>100_000_000, valid=>1},
    {schema=>["date"], input=>100_000, valid=>0},

    # fudged for now because we haven't reimplemented coercion for clause/attr value
    #{schema=>["date", min=>"2014-01-01"], input=>"2013-12-12", valid=>0},
    #{schema=>["date", min=>"2014-01-02"], input=>"2014-01-02", valid=>1},
    #{schema=>["date", min=>"2014-01-02"], input=>"2014-02-01", valid=>1},

    #{schema=>["date", min=>"2014-01-02T02:10:10Z"],
    # input=>"2014-01-02", valid=>0},
    #{schema=>["date", min=>"2014-01-02T02:10:10Z"],
    # input=>"2014-02-01T03:00:00Z", valid=>1},

    #{schema=>["date", min=>"2014-01-02"], input=>1_000_000_000, valid=>0},
    #{schema=>["date", min=>"2014-01-02"], input=>2_000_000_000, valid=>1},
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
