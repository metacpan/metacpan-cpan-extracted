#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c;

    $c = gen_coercer(
        type=>"num",
        coerce_rules=>["str_num_en"],
        return_type => "status+err+val",
    );

    my $res;

    is_deeply($c->({}), [undef, undef, {}], "hashref uncoerced");
    is_deeply($c->("foo"), [1, "Invalid number: foo", undef]);
    is_deeply($c->("12"), [1, undef, 12]);
    is_deeply($c->("12,000"), [1, undef, 12_000]);
    is_deeply($c->("12,000,000"), [1, undef, 12_000_000]);
    is_deeply($c->("12,000,000.12"), [1, undef, 12_000_000.12]);

    $c = gen_coercer(
        type=>"int",
        coerce_rules=>["str_num_en"],
        return_type => "status+err+val",
    );
    is_deeply($c->("12,000"), [1, undef, 12_000]);

    $c = gen_coercer(
        type=>"float",
        coerce_rules=>["str_num_en"],
        return_type => "status+err+val",
    );
    is_deeply($c->("12,000"), [1, undef, 12_000]);
};

done_testing;
