#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["From_str::to_upper_first"]);

    # uncoerced
    is_deeply($c->({}), {}, "hashref uncoerced");
    is_deeply($c->("foo"), "Foo");
    is_deeply($c->("Foo"), "Foo");
    is_deeply($c->("FOO"), "FOO");
};

done_testing;
