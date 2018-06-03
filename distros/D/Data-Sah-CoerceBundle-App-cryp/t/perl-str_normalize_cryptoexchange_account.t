#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["str_normalize_cryptoexchange_account"]);

    # uncoerced
    is_deeply($c->({}), {}, "hashref uncoerced");

    dies_ok { $c->("foo") } "unknown exchange -> dies";
    dies_ok { $c->("gdax/a b") } "invalid account syntax -> dies";

    is_deeply($c->("GDAX"), "gdax/default");
    is_deeply($c->("gdax/1"), "gdax/1");
    is_deeply($c->("bx/2"), "bx-thailand/2");
    is_deeply($c->("BX thailand/Three"), "bx-thailand/Three");

};

done_testing;
