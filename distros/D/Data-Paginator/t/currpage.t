use Test::More;

use Data::Paginator;

my $pager = Data::Paginator->new({
    total_entries       => 24,
    entries_per_page    => 4,   # This means there will be 6 pages
    current_page        => 1,
});

$pager->current_page(12);

cmp_ok($pager->current_page, '==', 1);

done_testing;