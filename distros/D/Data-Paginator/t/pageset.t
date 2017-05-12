#!/usr/bin/perl -w
use strict;

use Test::More;
use Data::Paginator;

{
    my $pager = Data::Paginator->new({
        total_entries       => 24,
        entries_per_page    => 4,   # This means there will be 6 pages
        current_page        => 1,
        pages_per_set       => 2    # 3 sets
    });

    cmp_ok($pager->current_set, '==', 1, 'current set is 1');
    cmp_ok($pager->set_for(1), '==', 1, 'page 1 is in 1st set');
    cmp_ok($pager->set_for(3), '==', 2, 'page 3 is in 2nd set');

    cmp_ok($pager->next_set, '==', 9, 'next set page is 9');
    ok(!defined($pager->previous_set), 'previous set is undefined');
}

{
    my $pager = Data::Paginator->new({
        total_entries       => 24,
        entries_per_page    => 4,   # This means there will be 6 pages
        current_page        => 3,
        pages_per_set       => 2    # 3 sets
    });

    cmp_ok($pager->current_set, '==', 2, 'current set is 2');
    cmp_ok($pager->next_set, '==', 17, 'next set page is 9');
    cmp_ok($pager->previous_set, '==', 1, 'previous set page is 1');
}

{
    my $pager = Data::Paginator->new({
        total_entries       => 24,
        entries_per_page    => 4,   # This means there will be 6 pages
        current_page        => 5,
        pages_per_set       => 2    # 3 sets
    });

    cmp_ok($pager->current_set, '==', 3, 'current set is 3');
    ok(!defined($pager->next_set), 'next set page is undefined');
    cmp_ok($pager->previous_set, '==', 9, 'next set page is 9');
}

done_testing;