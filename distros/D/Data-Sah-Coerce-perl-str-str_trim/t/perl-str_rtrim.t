#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["str_rtrim"]);

    # uncoerced
    is_deeply($c->({}), {}, "hashref uncoerced");

    # spaces
    is_deeply($c->("a"), "a");
    is_deeply($c->("b "), "b");
    is_deeply($c->("  c"), "  c");
    is_deeply($c->(" d  "), " d");

    # newlines
    is_deeply($c->("a"), "a");
    is_deeply($c->("b\n"), "b");
    is_deeply($c->("\n\nc"), "\n\nc");
    is_deeply($c->("\nd\n\n"), "\nd");

    # XXX tabs
};

done_testing;
