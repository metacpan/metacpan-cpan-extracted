#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::CoerceJS qw(gen_coercer);
use Nodejs::Util qw(get_nodejs_path);

plan skip_all => 'node.js is not available' unless get_nodejs_path();

subtest "coerce_to=boolean" => sub {
    my $c = gen_coercer(type=>"bool");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is_deeply($c->("foo"), "foo", "uncoerced");
        is_deeply($c->(2), 2, "uncoerced");
    };
    subtest "from str" => sub {
        ok($c->("yes"));
        ok($c->("true"));
        ok($c->("on"));
        ok($c->("1"));

        ok(!$c->("no"));
        ok(!$c->("false"));
        ok(!$c->("off"));
        ok(!$c->("0"));
    };
};

done_testing;
