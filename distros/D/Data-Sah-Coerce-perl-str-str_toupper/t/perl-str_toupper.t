#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["str_toupper"]);

    # uncoerced
    is_deeply($c->({}), {}, "hashref uncoerced");
    is_deeply($c->("foo"), "FOO");
    is_deeply($c->("Foo"), "FOO");
    is_deeply($c->("FOO"), "FOO");
};

done_testing;
