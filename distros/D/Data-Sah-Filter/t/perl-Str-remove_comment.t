#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

my $filter;

# default style
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::remove_comment"] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef), [undef, undef]);
is_deeply($filter->("foo # comment\nbar # another comment\nbaz // comment"), [undef, "foo\nbar\nbaz // comment"]);

# cpp style
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::remove_comment" => {style=>"cpp"}] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef), [undef, undef]);
is_deeply($filter->("foo # comment\nbar # another comment\nbaz // comment"), [undef, "foo # comment\nbar # another comment\nbaz"]);

done_testing;
