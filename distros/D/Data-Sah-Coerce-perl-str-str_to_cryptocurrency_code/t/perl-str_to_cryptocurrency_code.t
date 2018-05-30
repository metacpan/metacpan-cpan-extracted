#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"str", coerce_rules=>["str_to_cryptocurrency_code"]);

    # uncoerced
    is_deeply($c->({}), {}, "hashref uncoerced");

    is_deeply($c->("Btc"), "BTC");
    is_deeply($c->("bitcoin"), "BTC");
    is_deeply($c->("ethereum classic"), "ETC");
    is_deeply($c->("Ethereum-Classic"), "ETC");

    dies_ok { $c->("foo") };

};

done_testing;
