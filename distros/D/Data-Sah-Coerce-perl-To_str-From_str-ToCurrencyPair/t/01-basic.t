#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"str",
        coerce_rules=>["From_str::ToCurrencyPair"],
        return_type=>"status+err+val",
    );

    my $res;

    is_deeply($c->({}), [undef, undef, {}]);

    is_deeply($c->("usd"), [1, "Invalid currency pair syntax, please use CUR1/CUR2 syntax", undef]);
    is_deeply($c->("usd/usd"), [1, "Base currency and quote currency must differ", undef]);
    is_deeply($c->("foo/usd"), [1, "Unknown base currency code: FOO", undef]);
    is_deeply($c->("usd/zzz"), [1, "Unknown quote currency code: ZZZ", undef]);

    is_deeply($c->("USD/IDR"), [1, undef, "USD/IDR"]);
    is_deeply($c->("usd/idr"), [1, undef, "USD/IDR"]);
};

done_testing;
