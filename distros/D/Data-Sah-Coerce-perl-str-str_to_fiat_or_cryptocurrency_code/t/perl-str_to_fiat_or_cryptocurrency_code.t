#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"str",
        coerce_rules=>["str_to_fiat_or_cryptocurrency_code"],
        return_type=>"status+err+val",
    );

    my $res;

    is_deeply($c->({}), [undef, undef, {}]);

    # fiat
    is_deeply($c->("usd"), [1, undef, "USD"]);
    is_deeply($c->("IDR"), [1, undef, "IDR"]);

    # crypto
    is_deeply($c->("Btc"), [1, undef, "BTC"]);
    is_deeply($c->("bitcoin"), [1, undef, "BTC"]);
    is_deeply($c->("ethereum classic"), [1, undef, "ETC"]);
    is_deeply($c->("Ethereum-Classic"), [1, undef, "ETC"]);
    is_deeply($c->("foo"), [1, "Unknown fiat/cryptocurrency code/name/safename: foo", undef]);
};

done_testing;
