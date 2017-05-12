#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( lib t/lib );


use_ok('My::State');

My::State->do_transaction(sub {
  map { $_->delete } My::State->retrieve_all;

  # Make some fake data:
  for( 1..49 )
  {
    My::State->create(
      state_name  => "A State " . sprintf('%03d', $_),
      state_abbr  => "S" . sprintf('%03d', $_),
    );
  }# end for()
});

my $pager = My::State->pager(undef, {
  order_by    => 'state_name ASC',
  page_size   => 10,
  page_number => 1,
});

$pager->next_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( ! $pager->has_prev,           "Can't show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 1,   "Page number is correct" );
is( $pager->start_item    => 1,   "Start item is correct" );
is( $pager->stop_item     => 10,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->next_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( $pager->has_prev,             "Can show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 2,   "Page number is correct" );
is( $pager->start_item    => 11,   "Start item is correct" );
is( $pager->stop_item     => 20,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->next_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( $pager->has_prev,             "Can show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 3,   "Page number is correct" );
is( $pager->start_item    => 21,   "Start item is correct" );
is( $pager->stop_item     => 30,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->next_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( $pager->has_prev,             "Can show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 4,   "Page number is correct" );
is( $pager->start_item    => 31,   "Start item is correct" );
is( $pager->stop_item     => 40,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->next_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( $pager->has_prev,             "Can show prev" );
ok( ! $pager->has_next,           "Can't show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 5,   "Page number is correct" );
is( $pager->start_item    => 41,  "Start item is correct" );
is( $pager->stop_item     => 49,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->prev_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( $pager->has_prev,             "Can show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 4,   "Page number is correct" );
is( $pager->start_item    => 31,   "Start item is correct" );
is( $pager->stop_item     => 40,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->prev_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( $pager->has_prev,             "Can show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 3,   "Page number is correct" );
is( $pager->start_item    => 21,   "Start item is correct" );
is( $pager->stop_item     => 30,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->prev_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( $pager->has_prev,             "Can show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 2,   "Page number is correct" );
is( $pager->start_item    => 11,   "Start item is correct" );
is( $pager->stop_item     => 20,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );

$pager->prev_page;
is( $pager->total_pages   => 5,   "Total pages is correct" );
ok( !$pager->has_prev,            "Can't show prev" );
ok( $pager->has_next,             "Can show next" );
is( $pager->page_size     => 10,  "Page size is correct" );
is( $pager->page_number   => 1,   "Page number is correct" );
is( $pager->start_item    => 1,   "Start item is correct" );
is( $pager->stop_item     => 10,  "Stop item is correct" );
is( $pager->total_items   => 49,  "Total items is correct" );


for( 1..4 )
{
  ok( $pager->next_page, "Got next page" );
  ok( $pager->has_prev, "Has prev" );
  if( $_ < 4 )
  {
    ok( $pager->has_next, "Has next" );
  }# end if()
}

ok( ! $pager->next_page, "Pages exhausted" );

for( 1..4 )
{
  ok( $pager->prev_page, "Got next page" );
  ok( $pager->has_next, "Has next" );
  if( $pager->page_number > 1 )
  {
    ok( $pager->has_prev, "Has prev (" . $pager->page_number . ")" );
  }# end if()
}


MIDDLE_A: {
  $pager = My::State->pager(undef, {
    order_by    => 'state_name ASC',
    page_size   => 10,
    page_number => 2,
  });
  $pager->next_page;
  is( $pager->total_pages   => 5,   "Total pages is correct" );
  ok( $pager->has_prev,             "Can show prev" );
  ok( $pager->has_next,             "Can show next" );
  is( $pager->page_size     => 10,  "Page size is correct" );
  is( $pager->page_number   => 2,   "Page number is correct" );
  is( $pager->start_item    => 11,   "Start item is correct" );
  is( $pager->stop_item     => 20,  "Stop item is correct" );
  is( $pager->total_items   => 49,  "Total items is correct" );
};

MIDDLE_B: {
  $pager = My::State->pager(undef, {
    order_by    => 'state_name ASC',
    page_size   => 10,
    page_number => 2,
  });
  $pager->prev_page;
  is( $pager->total_pages   => 5,   "Total pages is correct" );
  ok( $pager->has_prev,             "Can show prev" );
  ok( $pager->has_next,             "Can show next" );
  is( $pager->page_size     => 10,  "Page size is correct" );
  is( $pager->page_number   => 2,   "Page number is correct" );
  is( $pager->start_item    => 11,   "Start item is correct" );
  is( $pager->stop_item     => 20,  "Stop item is correct" );
  is( $pager->total_items   => 49,  "Total items is correct" );
  
  $pager->prev_page;
  is( $pager->total_pages   => 5,   "Total pages is correct" );
  ok( !$pager->has_prev,            "Can't show prev" );
  ok( $pager->has_next,             "Can show next" );
  is( $pager->page_size     => 10,  "Page size is correct" );
  is( $pager->page_number   => 1,   "Page number is correct" );
  is( $pager->start_item    => 1,   "Start item is correct" );
  is( $pager->stop_item     => 10,  "Stop item is correct" );
  is( $pager->total_items   => 49,  "Total items is correct" );
};

