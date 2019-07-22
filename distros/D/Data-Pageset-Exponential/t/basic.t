#!perl

use Test::More;

use_ok('Data::Pageset::Exponential');

ok my $pager = Data::Pageset::Exponential->new(), 'constructor';

is $pager->total_entries, 0, 'total_entries';

is $pager->total_entries(100), 100, 'set total_entries';

is $pager->entries_per_page, 10, 'entries_per_page (default)';

is $pager->current_page, 1, 'current_page';

is $pager->current_page(2), 2, 'set current_page';
is $pager->current_page, 2, 'current_page';

is $pager->first, 11, 'first';

is $pager->entries_per_page(5), 5, 'set entries_per_page';

is $pager->current_page, 3, 'current_page';

is $pager->first, 11, 'first';

is $pager->total_entries(1200), 1200, 'set total_entries';
is $pager->last_page, 240, 'last_page';
is $pager->current_page(1), 1, 'set current_page';

is_deeply $pager->series, [
    -2999, -1999, -999,    #
    -299,  -199,  -99,     #
    -29,   -19,   -9,      #
    -2 .. 2,               #
    9,   19,   29,         #
    99,  199,  299,        #
    999, 1999, 2999,       #
  ],
  'series';

is $pager->max_pages_per_set => 23, 'pages_per_set';

is_deeply $pager->pages_in_set, [
    1 .. 3,                #
    10, 20, 30,            #
    100, 200               #
  ],
  'pages_in_set';

is $pager->next_set, 6, 'next_set';
is $pager->previous_set, undef, 'previous_set';

is $pager->current_page(50), 50, 'set current_page';

is_deeply $pager->pages_in_set, [
    21, 31, 41,            #
    48 .. 52,              #
    59, 69, 79,            #
    149,                   #
  ],
  'pages_in_set';

is $pager->next_set, 55, 'next_set';
is $pager->previous_set, 43, 'previous_set';

done_testing;
