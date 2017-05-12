#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::CoerceJS qw(gen_coercer);
use Nodejs::Util qw(get_nodejs_path);
use Test::More 0.98;

plan skip_all => 'node.js is not available' unless get_nodejs_path();

subtest "coerce_to=Date" => sub {
    my $c = gen_coercer(type=>"date");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is($c->(1), 1);
    };
    subtest "from integer" => sub {
        is($c->(100_000_000), "1973-03-03T09:46:40.000Z");
    };
    # XXX from Date object
    subtest "from string" => sub {
        is($c->("2016-01-01"), "2016-01-01T00:00:00.000Z");
        is($c->("2016-01-01T12:34:56"), "2016-01-01T12:34:56.000Z");
    };
};

done_testing;
