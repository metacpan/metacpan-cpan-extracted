#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Test::Memory::Cycle;
use lib qw( lib t/lib );
use My::User;

$_->delete foreach My::User->retrieve_all;
My::User->create(
  user_first_name => 'firstname',
  user_last_name  => 'lastname',
  user_email      => 'test@test.com',
  user_password   => 'pass'
);

my $user = My::User->retrieve_all->first;
#$user->delete;

memory_cycle_ok( $user );


