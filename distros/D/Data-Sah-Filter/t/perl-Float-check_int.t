#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

my $filter;

$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ "Float::check_int" ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(1)  , [undef, 1]);
is_deeply($filter->(1.1), ["Number must be an integer", 1.1]);

done_testing;
