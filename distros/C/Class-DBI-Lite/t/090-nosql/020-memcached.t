#!/usr/bin/perl -w

use strict;
use warnings 'all';
use lib qw( t/lib lib );
use Test::More;

eval {
  require Class::DBI::Lite::CacheManager::Memcached;
  require My::User;
  My::User->set_cache(
    Class::DBI::Lite::CacheManager::Memcached->new(
      lifetime  => '5s',
      class     => 'My::User',
      servers   => ['127.0.0.1:11211'],
      do_cache_search => 1,
    )
  );
};
if( $@ )
{
  plan (skip_all => "memcached does not appear to be running" );
  exit;
}
else
{
  plan 'no_plan';
}# end if()

use_ok('My::City');
use_ok('My::State');


map { $_->delete } My::City->retrieve_all;
map { $_->delete } My::State->retrieve_all;
map { $_->delete } My::User->retrieve_all;

my @user_ids = ( );
for( 1..10 )
{
  push @user_ids, My::User->create(
    user_first_name => 'firstname',
    user_last_name  => 'lastname',
    user_email      => $_ . '_test@test.com',
    user_password   => 'pass'
  )->id;
}# end for()

My::User->cache->cache_searches_containing(qw(
  user_email
));

for( 1..1000 )
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

ok(1);

