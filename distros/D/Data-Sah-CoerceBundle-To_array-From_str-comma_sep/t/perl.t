#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Coerce qw(gen_coercer);
use Test::More 0.98;

subtest "coerce_to=array" => sub {
    my $c;

    # default separator ,
    $c = gen_coercer(type=>"array", coerce_rules=>["From_str::comma_sep"]);
    is_deeply($c->({}), {}, "uncoerced");
    is_deeply($c->([[]]), [[]], "uncoerced");
    is_deeply($c->("a"), ["a"]);
    is_deeply($c->("a, b"), ["a", "b"]);
    is_deeply($c->("a; b"), ["a; b"]);

    # arg:separator
    $c = gen_coercer(type=>"array", coerce_rules=>[ ["From_str::comma_sep",{separator=>";"}] ]);
    is_deeply($c->({}), {}, "uncoerced");
    is_deeply($c->([[]]), [[]], "uncoerced");
    is_deeply($c->("a"), ["a"]);
    is_deeply($c->("a, b"), ["a, b"]);
    is_deeply($c->("a; b"), ["a", "b"]);
};

done_testing;
