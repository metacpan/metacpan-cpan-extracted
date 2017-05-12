use strict;
use warnings;
use Test::More;
use Test::Differences;
use DBIx::Skinny::Pager::Page;

my $pager = DBIx::Skinny::Pager::Page->new(70, 20, 2);

eq_or_diff($pager->to_hash, +{
    total_entries    => 70,
    current_page     => 2,
    entries_per_page => 20,
    previous_page    => 1,
    next_page        => 3,
}, "ok");

done_testing();

