use Test::More;

use Data::Paginator;

{
    my $pager = Data::Paginator->new({
        total_entries       => 24,
        entries_per_page    => 4,   # This means there will be 6 pages
        current_page        => 1,
    });

    cmp_ok($pager->page_for(1), '==', 1, '1st item is on 1st page');
    cmp_ok($pager->page_for(11), '==', 3, '11th item is on 3rd page');
    cmp_ok($pager->page_for(9), '==', 3, '9th item is on 3rd page');
    cmp_ok($pager->page_for(12), '==', 3, '12th item is on 3rd page');
    cmp_ok($pager->page_for(24), '==', 6, '24th item is on 6th page');
    ok(!defined($pager->page_for(-12)), '-12 is on no page');
    ok(!defined($pager->page_for(112)), '112 is on no page');
}

{
    my $pager = Data::Paginator->new({
        total_entries       => 24,
        entries_per_page    => 4,   # This means there will be 6 pages
        current_page        => -1,
    });

    cmp_ok($pager->current_page, '==', 1, '-1 current_page yields 1');
}

{
    my $pager = Data::Paginator->new({
        total_entries       => 24,
        entries_per_page    => 4,   # This means there will be 6 pages
        current_page        => 111,
    });

    cmp_ok($pager->current_page, '==', 6, '111 current_page yields 6');
}

done_testing;