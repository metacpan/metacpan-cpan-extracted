#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"str",
        coerce_rules=>["str_to_cryptoexchange_currency_pair"],
        return_type=>"status+err+val",
    );

    my $res;

    is_deeply($c->({}), [undef, undef, {}]);

    is_deeply($c->("usd"), [1, "Invalid currency pair syntax, please use CUR1/CUR2 syntax", undef]);
    is_deeply($c->("btc/btc"), [1, "Currency and base currency must differ", undef]);
    is_deeply($c->("gbp/usd"), [1, "Unknown cryptocurrency code: gbp", undef]);
    is_deeply($c->("btc/zzz"), [1, "Unknown fiat/cryptocurrency code: ZZZ", undef]);
    is_deeply($c->("bitcoin/usd"), [1, "Unknown cryptocurrency code: bitcoin", undef]);

    is_deeply($c->("btc/usd"), [1, undef, "BTC/USD"]);
};

done_testing;
