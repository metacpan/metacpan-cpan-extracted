#!/usr/bin/perl -w

use strict;
use warnings 'all';
use lib qw( t/lib lib );
use Test::More 'no_plan';

use_ok('Class::DBI::Lite::CacheManager::InMemory');
use_ok('My::City');
use_ok('My::State');
use_ok('My::User');

My::User->set_cache(
  Class::DBI::Lite::CacheManager::InMemory->new(
    lifetime  => '5s',
    class     => 'My::User',
    do_cache_search => 1,
  )
);


map { $_->delete } My::City->retrieve_all;
map { $_->delete } My::State->retrieve_all;
map { $_->delete } My::User->retrieve_all;

my @user_ids = ( );
for( 1..10 )
{
  push @user_ids, My::User->create(
    user_first_name => $_ . '_firstname',
    user_last_name  => $_ . '_lastname',
    user_email      => $_ . '_test@test.com',
    user_password   => $_ . '_pass'
  )->id;
}# end for()

My::User->cache->cache_searches_containing(qw(
  user_email
));

use Data::Dumper;
for( 1..10000 )
{
  for( 1..10 )
  {
    my $email = "$_\_test\@test.com";
    my ($res) = My::User->search( user_email => $email );
  }# end for()
}# end for()


for( 1..1_000 )
{
  for( @user_ids )
  {
    My::User->retrieve( $_ )->id;
  }# end for()
}

My::User->cache->clear;

map { $_->delete } My::City->retrieve_all;
map { $_->delete } My::State->retrieve_all;
map { $_->delete } My::User->retrieve_all;

