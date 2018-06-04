#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"str",
        coerce_rules=>["str_to_cryptoexchange_safename"],
        return_type=>"status+err+val",
    );

    is_deeply($c->({}), [undef, undef, {}], "hashref uncoerced");
    is_deeply($c->("GDAX"), [1, undef, "gdax"]);
    is_deeply($c->("bx thailand"), [1, undef, "bx-thailand"]);
    is_deeply($c->("BX-Thailand"), [1, undef, "bx-thailand"]);
    is_deeply($c->("foo"), [1, "Unknown cryptoexchange code/name/safename: foo", undef]);
};

done_testing;
