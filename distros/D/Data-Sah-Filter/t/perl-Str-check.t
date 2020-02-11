#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah::Filter qw(gen_filter);

my $filter;

# min_len
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::check",{min_len=>3}] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef), [undef, undef]);
is_deeply($filter->("foo"), [undef, "foo"]);
is_deeply($filter->("fo") , ["Length of data must be at least 3", undef]);

# max_len
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::check",{max_len=>3}] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef) , [undef, undef]);
is_deeply($filter->("foo") , [undef, "foo"]);
is_deeply($filter->("food"), ["Length of data must be at most 3", undef]);

# max_len
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::check",{max_len=>3}] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef) , [undef, undef]);
is_deeply($filter->("foo") , [undef, "foo"]);
is_deeply($filter->("food"), ["Length of data must be at most 3", undef]);

# match
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::check",{match=>'[abc]'}] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef) , [undef, undef]);
is_deeply($filter->("bar") , [undef, "bar"]);
{
    my $tmp = $filter->("qux");
    like($tmp->[0], qr/Data must match/);
    is_deeply($tmp->[1], undef);
}

# in
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::check",{in=>[qw/a b c/]}] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef) , [undef, undef]);
is_deeply($filter->("a") , [undef, "a"]);
is_deeply($filter->("d"), ["Data must be one of a, b, c", undef]);

# combine
$filter = Data::Sah::Filter::gen_filter(
    filter_names=>[ ["Str::check",{min_len=>3, max_len=>4}] ],
    return_type=>"str_errmsg+val",
);
is_deeply($filter->(undef)   , [undef, undef]);
is_deeply($filter->("foo")   , [undef, "foo"]);
is_deeply($filter->("fo")    , ["Length of data must be at least 3", undef]);
is_deeply($filter->("foobar"), ["Length of data must be at most 4", undef]);

done_testing;
