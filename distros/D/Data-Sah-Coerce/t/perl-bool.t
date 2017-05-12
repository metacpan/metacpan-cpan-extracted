#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;
use Test::Needs;

subtest "coerce_to=" => sub {
    my $c = gen_coercer(type=>"bool");

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is_deeply($c->("foo"), "foo", "uncoerced");
        is_deeply($c->(2), 2, "uncoerced");
        is_deeply("true", "true", "uncoerced");
    };
};

subtest "coerce_to=, +rule str" => sub {
    my $c = gen_coercer(type=>"bool", coerce_rules=>["str"]);

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
        is_deeply($c->("foo"), "foo", "uncoerced");
        is_deeply($c->(2), 2, "uncoerced");
    };
    subtest "from str" => sub {
        is($c->("yes"), 1);
        is($c->("true"), 1);
        is($c->("on"), 1);

        is($c->("no"), '');
        is($c->("false"), '');
        is($c->("off"), '');
        is($c->("0"), '');
    };
};

done_testing;
