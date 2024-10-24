#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["From_str::to_lower_first"]);

    # uncoerced
    is_deeply($c->({}), {}, "hashref uncoerced");
    is_deeply($c->("foo"), "foo");
    is_deeply($c->("Foo"), "foo");
    is_deeply($c->("FOO"), "fOO");
};

done_testing;
