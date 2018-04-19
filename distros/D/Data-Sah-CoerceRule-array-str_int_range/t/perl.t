#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;

subtest "coerce_to=array" => sub {
    my $c = gen_coercer(type=>"array", coerce_rules=>["str_int_range"]);

    # uncoerced
    is_deeply($c->({}), {}, "uncoerced");
    is_deeply($c->([[]]), [[]], "uncoerced");
    is_deeply($c->("a"), "a", "uncoerced");
    is_deeply($c->("a-1"), "a-1", "uncoerced");

    is_deeply($c->("1-10"), [1..10]);
    is_deeply($c->("1..10"), [1..10]);
    is_deeply($c->("10-1"), []);
    is_deeply($c->("10..1"), []);
    is_deeply($c->("-3-3"), [-3..3]);
    is_deeply($c->("-3..3"), [-3..3]);
    is_deeply($c->("-3 - -1"), [-3..-1]);
    is_deeply($c->("-3 .. -1"), [-3..-1]);
};

done_testing;
