#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

my $filter = Data::Sah::Filter::gen_filter(filter_names=>[ ["Str::replace_map",{map=>{foo=>"bar", baz=>"qux"}}] ]);
is_deeply($filter->(undef), undef);
is_deeply($filter->("foo"), "bar");
is_deeply($filter->("bar"), "bar");
is_deeply($filter->("baz"), "qux");
is_deeply($filter->("Foo"), "Foo");

done_testing;
