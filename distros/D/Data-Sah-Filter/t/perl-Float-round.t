#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

my $filter = Data::Sah::Filter::gen_filter(filter_names=>["Float::round"]);
is_deeply($filter->(1), 1);
is_deeply($filter->(-1.1), -1);
is_deeply($filter->(-1.6), -2);
is_deeply($filter->(1.1), 1);
is_deeply($filter->(1.6), 2);

# nearest arg
$filter = Data::Sah::Filter::gen_filter(filter_names=>[ ["Float::round", {nearest=>10}] ]);
is_deeply($filter->(19), 20);
is_deeply($filter->(23), 20);
$filter = Data::Sah::Filter::gen_filter(filter_names=>[ ["Float::round", {nearest=>0.5}] ]);
is_deeply($filter->(19), 19);
is_deeply($filter->(19.5), 19.5);
is_deeply($filter->(19.65), 19.5);
is_deeply($filter->(19.85), 20);

done_testing;
