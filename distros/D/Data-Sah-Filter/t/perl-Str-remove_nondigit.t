#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

my $filter;

$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::remove_nondigit"] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef), [undef, undef]);
is_deeply($filter->("555 123-4567"), [undef, "5551234567"]);

done_testing;
