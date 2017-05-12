#!perl -T

use strict;
use warnings;

use Test::More tests => 17;
use Test::NoWarnings;
use Test::Exception;
use Data::Page;

BEGIN {
    use_ok 'Data::Page::Pagination';
}

# Data::Page->new($total_entries, $entries_per_page, $current_page);

throws_ok
    sub {
        Data::Page::Pagination->new(
            page         => undef,
            page_numbers => 3,
        );
    },
    qr{\QAttribute (page) does not pass the type constraint}xms,
    'page number undef';
throws_ok
    sub {
        Data::Page::Pagination->new(
            page         => Data::Page->new,
            page_numbers => 2,
        );
    },
    qr{\QAttribute (page_numbers) does not pass the type constraint}xms,
    'page number 2';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(0, 10, 1),
            page_numbers => 3,
        )
        ->render_plaintext,
    '[1]',
    '0 pages only, 3 visible in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(10, 10, 1),
            page_numbers => 3,
        )
        ->render_plaintext,
    '[1]',
    '1 page only, 3 visible in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(20, 10, 1),
            page_numbers => 3,
        )
        ->render_plaintext,
    '[1] 2 >2',
    '2 pages only, 3 visible in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 1),
            page_numbers => 3,
        )
        ->render_plaintext,
    '[1] 2 .. 9 >2',
    'first page, 3 visible in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 2),
            page_numbers => 3,
        )
        ->render_plaintext,
    '1< 1 [2] 3 .. 9 >3',
    'first page, 3 visible in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 5),
            page_numbers => 3,
        )
        ->render_plaintext,
    '4< 1 .. 4 [5] 6 .. 9 >6',
    'middle page, 3 visible in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 8),
            page_numbers => 3,
        )
        ->render_plaintext,
    '7< 1 .. 7 [8] 9 >9',
    'last page, 3 visable in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 9),
            page_numbers => 3,
        )
        ->render_plaintext,
    '8< 1 .. 8 [9]',
    'last page, 3 visable in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 1),
            page_numbers => 9,
        )
        ->render_plaintext,
    '[1] 2 3 4 5 .. 9 >2',
    'first page, 9 visable in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 2),
            page_numbers => 9,
        )
        ->render_plaintext,
    '1< 1 [2] 3 4 5 6 .. 9 >3',
    'first page, 9 visable in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 5),
            page_numbers => 9,
        )
        ->render_plaintext,
    '4< 1 2 3 4 [5] 6 7 8 9 >6',
    'middle page, 9 visable in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 8),
            page_numbers => 9,
        )
        ->render_plaintext,
    '7< 1 .. 4 5 6 7 [8] 9 >9',
    'last page, 9 visable in the middle';
is
    +Data::Page::Pagination
        ->new(
            page         => Data::Page->new(90, 10, 9),
            page_numbers => 9,
        )
        ->render_plaintext,
    '8< 1 .. 5 6 7 8 [9]',
    'last page, 9 visable in the middle';
