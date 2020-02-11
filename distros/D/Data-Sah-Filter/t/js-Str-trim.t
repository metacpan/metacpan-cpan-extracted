#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::FilterJS qw(gen_filter);
use Nodejs::Util qw(get_nodejs_path);

plan skip_all => 'node.js is not available' unless get_nodejs_path();

my $filter = Data::Sah::FilterJS::gen_filter(filter_names=>["Str::trim"]);
is_deeply($filter->(undef), undef);
is_deeply($filter->("foo"), "foo");
is($filter->(" foo "), "foo");

done_testing;
