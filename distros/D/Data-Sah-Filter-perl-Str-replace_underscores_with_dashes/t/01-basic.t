#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

subtest "basics" => sub {
    my $c = gen_filter(filter_names=>["Str::replace_underscores_with_dashes"], return_type=>"val");
    my $res;

    # unfiltered
    is_deeply($c->(undef), undef);

    # filtered
    is_deeply($c->("1_2-_3_4"), q(1-2--3-4));
};

done_testing;
