use strict;
use warnings;
use Test::More;
use Data::Page::Nav;

my $page = Data::Page::Nav->new;
$page->total_entries(110);
$page->entries_per_page(10);
$page->number_of_pages(5);

my @array = $page->pages_nav;
for my $number (@array) {
    like($number, qr/^[1-5]{1}$/, 'Test array number ' . $number);
}

my $array_ref = $page->pages_nav;
for my $number (@$array_ref) {
    like($number, qr/^[1-5]{1}$/, 'Test array ref number ' . $number);
}

my $na1 = join '-', $page->pages_nav;
is($na1, '1-2-3-4-5', 'Test na1');
is($page->first_nav_page, 1, 'Test na1 first nav page');
is($page->last_nav_page, 5, 'Test na1 last nav page');

$page->current_page(2);
my $na2 = join '-', $page->pages_nav;
is($na2, '1-2-3-4-5', 'Test na2');
is($page->first_nav_page, 1, 'Test na2 first nav page');
is($page->last_nav_page, 5, 'Test na2 last nav page');

$page->current_page(3);
my $na3 = join '-', $page->pages_nav;
is($na3, '1-2-3-4-5', 'Test na3');
is($page->first_nav_page, 1, 'Test na3 first nav page');
is($page->last_nav_page, 5, 'Test na3 last nav page');

$page->current_page(4);
my $na4 = join '-', $page->pages_nav;
is($na4, '2-3-4-5-6', 'Test na4');
is($page->first_nav_page, 2, 'Test na4 first nav page');
is($page->last_nav_page, 6, 'Test na4 last nav page');

$page->current_page(5);
my $na5 = join '-', $page->pages_nav;
is($na5, '3-4-5-6-7', 'Test na5');
is($page->first_nav_page, 3, 'Test na5 first nav page');
is($page->last_nav_page, 7, 'Test na5 last nav page');

$page->current_page(6);
my $na6 = join '-', $page->pages_nav;
is($na6, '4-5-6-7-8', 'Test na6');
is($page->first_nav_page, 4, 'Test na6 first nav page');
is($page->last_nav_page, 8, 'Test na6 last nav page');

$page->current_page(7);
my $na7 = join '-', $page->pages_nav;
is($na7, '5-6-7-8-9', 'Test na7');
is($page->first_nav_page, 5, 'Test na7 first nav page');
is($page->last_nav_page, 9, 'Test na7 last nav page');

$page->current_page(8);
my $na8 = join '-', $page->pages_nav;
is($na8, '6-7-8-9-10', 'Test na8');
is($page->first_nav_page, 6, 'Test na8 first nav page');
is($page->last_nav_page, 10, 'Test na8 last nav page');

$page->current_page(9);
my $na9 = join '-', $page->pages_nav;
is($na9, '7-8-9-10-11', 'Test na9');
is($page->first_nav_page, 7, 'Test na9 first nav page');
is($page->last_nav_page, 11, 'Test na9 last nav page');

$page->current_page(10);
my $na10 = join '-', $page->pages_nav;
is($na10, '7-8-9-10-11', 'Test na10');
is($page->first_nav_page, 7, 'Test na10 first nav page');
is($page->last_nav_page, 11, 'Test na10 last nav page');

$page->current_page(11);
my $na11 = join '-', $page->pages_nav;
is($na11, '7-8-9-10-11', 'Test na11');
is($page->first_nav_page, 7, 'Test na11 first nav page');
is($page->last_nav_page, 11, 'Test na11 last nav page');

$page->current_page(1);
my $nb1 = join '-', $page->pages_nav(6);
is($nb1, '1-2-3-4-5-6', 'Test nb1');
is($page->first_nav_page, 1, 'Test nb1 first nav page');
is($page->last_nav_page, 6, 'Test nb1 last nav page');

$page->current_page(2);
my $nb2 = join '-', $page->pages_nav(6);
is($nb2, '1-2-3-4-5-6', 'Test nb2');
is($page->first_nav_page, 1, 'Test nb2 first nav page');
is($page->last_nav_page, 6, 'Test nb2 last nav page');

$page->current_page(3);
my $nb3 = join '-', $page->pages_nav(6);
is($nb3, '1-2-3-4-5-6', 'Test nb3');
is($page->first_nav_page, 1, 'Test nb3 first nav page');
is($page->last_nav_page, 6, 'Test nb3 last nav page');

$page->current_page(4);
my $nb4 = join '-', $page->pages_nav(6);
is($nb4, '2-3-4-5-6-7', 'Test nb4');
is($page->first_nav_page, 2, 'Test nb4 first nav page');
is($page->last_nav_page, 7, 'Test nb4 last nav page');

$page->current_page(5);
my $nb5 = join '-', $page->pages_nav(6);
is($nb5, '3-4-5-6-7-8', 'Test nb5');
is($page->first_nav_page, 3, 'Test nb5 first nav page');
is($page->last_nav_page, 8, 'Test nb5 last nav page');

$page->current_page(6);
my $nb6 = join '-', $page->pages_nav(6);
is($nb6, '4-5-6-7-8-9', 'Test nb6');
is($page->first_nav_page, 4, 'Test nb6 first nav page');
is($page->last_nav_page, 9, 'Test nb6 last nav page');

$page->current_page(7);
my $nb7 = join '-', $page->pages_nav(6);
is($nb7, '5-6-7-8-9-10', 'Test nb7');
is($page->first_nav_page, 5, 'Test nb7 first nav page');
is($page->last_nav_page, 10, 'Test nb7 last nav page');

$page->current_page(8);
my $nb8 = join '-', $page->pages_nav(6);
is($nb8, '6-7-8-9-10-11', 'Test nb8');
is($page->first_nav_page, 6, 'Test nb8 first nav page');
is($page->last_nav_page, 11, 'Test nb8 last nav page');

$page->current_page(9);
my $nb9 = join '-', $page->pages_nav(6);
is($nb9, '6-7-8-9-10-11', 'Test nb9');
is($page->first_nav_page, 6, 'Test nb9 first nav page');
is($page->last_nav_page, 11, 'Test nb9 last nav page');

$page->current_page(10);
my $nb10 = join '-', $page->pages_nav(6);
is($nb10, '6-7-8-9-10-11', 'Test nb10');
is($page->first_nav_page, 6, 'Test nb10 first nav page');
is($page->last_nav_page, 11, 'Test nb10 last nav page');

$page->current_page(11);
my $nb11 = join '-', $page->pages_nav(6);
is($nb11, '6-7-8-9-10-11', 'Test nb11');
is($page->first_nav_page, 6, 'Test nb11 first nav page');
is($page->last_nav_page, 11, 'Test nb11 last nav page');

my $page2 = Data::Page::Nav->new;
$page2->total_entries(110);
$page2->current_page(6);
$page2->entries_per_page(10);

is($page2->first_nav_page(5), 4, 'Test the first nav page with number of pages: 5');
is($page2->last_nav_page(5), 8, 'Test the last nav page with number of pages: 5');

is($page2->first_nav_page, 4, 'Test the first nav page without the number of pages, it will continue the last value: 5');
is($page2->last_nav_page, 8, 'Test the last nav page without the number of pages, it will continue the last value: 5');

is($page2->first_nav_page(7), 3, 'Test the first nav page with number of pages: 7');
is($page2->last_nav_page(7), 9, 'Test the last nav page with number of pages: 7');

is($page2->first_nav_page, 3, 'Test the first nav page without the number of pages, it will continue the last value: 7');
is($page2->last_nav_page, 9, 'Test the last nav page without the number of pages, it will continue the last value: 7');

is($page2->first_nav_page(10), 2, 'Test the first nav page with number of pages: 10');
is($page2->last_nav_page(10), 11, 'Test the last nav page with number of pages: 10');

is($page2->first_nav_page, 2, 'Test the first nav page without the number of pages, it will continue the last value: 10');
is($page2->last_nav_page, 11, 'Test the last nav page without the number of pages, it will continue the last value: 10');

is($page2->first_nav_page(9), 2, 'Test the first nav page with number of pages: 9');
is($page2->last_nav_page, 10, 'Test the last nav page without the number of pages, it will continue the last value: 9');

done_testing;
