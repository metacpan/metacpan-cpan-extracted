#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["str_to_cryptoexchange_safename"]);

    # uncoerced
    is_deeply($c->({}), {}, "hashref uncoerced");

    is_deeply($c->("GDAX"), "gdax");
    is_deeply($c->("bx thailand"), "bx-thailand");
    is_deeply($c->("BX-Thailand"), "bx-thailand");

    dies_ok { $c->("foo") };

};

done_testing;
