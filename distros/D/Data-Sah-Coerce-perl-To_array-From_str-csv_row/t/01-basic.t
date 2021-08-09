#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(
        type=>"array",
        coerce_rules=>["From_str::csv_row"],
        return_type=>"status+val",
    );

    my $res;

    is_deeply($c->({}), [undef, {}]);

    is_deeply($c->("a"), [1, ['a']]);
    is_deeply($c->(q(a,"b c",,d)), [1, ['a','b c','','d']]);
};

done_testing;
