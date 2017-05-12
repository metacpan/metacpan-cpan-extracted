#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( t/lib lib );



use_ok('My::Model');
use_ok('My::User');
use_ok('My::City');
use_ok('My::State');

My::City->do_transaction(sub {
  map { $_->delete } My::City->retrieve_all;
  map { $_->delete } My::State->retrieve_all;
  map { $_->delete } My::User->retrieve_all;
});

My::User->create(
  user_first_name => 'firstname',
  user_last_name  => 'lastname',
  user_email      => 'test@test.com',
  user_password   => 'pass'
);

use_ok('My::State');

ok( My::State->retrieve_all->count == 0 );

my ($state) = My::State->retrieve_all;
is( $state => undef );

my $state1 = My::State->find_or_create(
  state_name  => "TestState",
  state_abbr  => "TE"
);

my $state2 = My::State->find_or_create(
  state_name  => "TestState",
  state_abbr  => "TE"
);

is_deeply $state1, $state2, "find_or_create() works";

