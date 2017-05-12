use strict;
use warnings;
use utf8;
use Test::More;
use Data::Page::NoTotalEntries;

subtest 'normal' => sub {
    my $pager = Data::Page::NoTotalEntries->new(
        has_next             => 1,
        entries_per_page     => 10,
        current_page         => 3,
        entries_on_this_page => 10,
    );
    is $pager->next_page(),     4;
    is $pager->prev_page(),     2;
    is $pager->previous_page(), 2;
    is $pager->first, 21;
    is $pager->last(), 30;
};

subtest 'first page' => sub {
    my $pager = Data::Page::NoTotalEntries->new(
        has_next         => 1,
        entries_per_page => 10,
        current_page     => 1,
        entries_on_this_page => 10,
    );
    is $pager->next_page(),     2;
    is $pager->prev_page(),     undef;
    is $pager->previous_page(), undef;
    is $pager->first, 1;
    is $pager->last(), 10;
};

subtest 'last page' => sub {
    my $pager = Data::Page::NoTotalEntries->new(
        has_next         => 0,
        entries_per_page => 10,
        current_page     => 99,
        entries_on_this_page => 5,
    );
    is $pager->next_page(),     undef;
    is $pager->prev_page(),     98;
    is $pager->previous_page(), 98;
    is $pager->first, 981;
    is $pager->last(), 985;
};

subtest 'not found page' => sub {
    my $pager = Data::Page::NoTotalEntries->new(
        has_next         => 0,
        entries_per_page => 10,
        current_page     => 99,
        entries_on_this_page => 0,
    );
    is $pager->next_page(),     undef;
    is $pager->prev_page(),     98;
    is $pager->previous_page(), 98;
    is $pager->first(), 0;
    is $pager->last(), 0;
};

done_testing;

