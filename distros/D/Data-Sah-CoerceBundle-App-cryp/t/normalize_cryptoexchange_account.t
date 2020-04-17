#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"str",
        coerce_rules=>["From_str::normalize_cryptoexchange_account"],
        return_type => "status+err+val",
    );

    my $res;

    is_deeply($c->({}), [undef, undef, {}], "hashref uncoerced");
    is_deeply($c->("foo"), [1, "Unknown cryptoexchange code/name/safename: foo", undef], "unknown exchange -> fail");
    is_deeply($c->("bitfinex/a b"), [1, "Invalid account syntax (a b), please only use letters/numbers/underscores/dashes", undef], "invalid account syntax -> fail");
    is_deeply($c->("bitfinex/".("a" x 65)), [1, "Account name too long (".("a" x 65)."), please do not exceed 64 characters", undef], "invalid account syntax -> fail");

    is_deeply($c->("Bitfinex"), [1, undef, "bitfinex/default"]);
    is_deeply($c->("bitfinex/1"), [1, undef, "bitfinex/1"]);
    is_deeply($c->("bx/2"), [1, undef, "bx-thailand/2"]);
    is_deeply($c->("BX thailand/Three"), [1, undef, "bx-thailand/Three"]);

};

done_testing;
