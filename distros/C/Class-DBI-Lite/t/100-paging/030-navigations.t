#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( lib t/lib );

use My::City;

my $state = My::State->find_or_create(
  state_name  => 'Colorado',
  state_abbr  => 'CO',
);

My::City->do_transaction(sub {
  My::City->db_Main->do("delete from cities");
  for(1..1000) {
    My::City->create(
      state_id  => $state->id,
      city_name => 'Unnamed City ' . sprintf('%04d', $_)
    );
  }
});

FIRST_PAGE: {
  my $pager = My::City->pager(undef, {
    page_size   => 10,
    page_number => 1,
  });

  my ($start, $stop) = $pager->navigations( 5 );
  is( $start => 1, "Start=1" );
  is( $stop  => 11, "Stop=11" );
};

PAGE_25: {
  my $pager = My::City->pager(undef, {
    page_size   => 25,
    page_number => 1,
  });

  my ($start, $stop) = $pager->navigations( 5 );
  is( $start => 1, "Start=20" );
  is( $stop  => 11, "Stop=30" );
};

LAST_PAGE: {
  my $pager = My::City->pager( undef, {
    page_size => 10,
    page_number => 100,
  });
  my ($start, $stop) = $pager->navigations( 5 );
  is( $start => 90, "Start=90" );
  is( $stop  => 100, "Stop=100" );
};

