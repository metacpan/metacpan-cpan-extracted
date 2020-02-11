#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

my $filter = Data::Sah::Filter::gen_filter(filter_names=>["Str::trim"]);
is_deeply($filter->(undef), undef);
is_deeply($filter->("foo"), "foo");
is($filter->(" foo "), "foo");

done_testing;
