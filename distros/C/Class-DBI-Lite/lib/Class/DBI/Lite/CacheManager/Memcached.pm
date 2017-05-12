
package Class::DBI::Lite::CacheManager::Memcached;

use strict;
use warnings 'all';
use base 'Class::DBI::Lite::CacheManager';
use Cache::Memcached;
use Carp 'confess';


sub defaults
{
  return (
    servers             => undef,
    compress_threshold  => 10_000,
    enable_compress     => 0,
    debug               => 0,
    lifetime            => '30s',
    class               => undef,
  );
}# end defaults()


# Public read-only properties:
sub servers             { shift->{servers} }
sub compress_threshold  { shift->{compress_threshold} }
sub enable_compress     { shift->{enable_compress} }
sub debug               { shift->{debug} }
sub memd                { shift->{class}->_meta->{memd} }

sub init
{
  my ($s) = @_;
  
  $s->{class}->_meta->{memd} = Cache::Memcached->new(
    servers             => $s->servers,
    compress_threshold  => $s->compress_threshold,
    enable_compress     => $s->enable_compress,
    debug               => $s->debug,
  );

  $s->{lifetime} ||= '30s';
  my ($number, $unit) = $s->{lifetime} =~ m/^(\d+)([smhd])$/i;
  $unit = uc($unit);
  confess "Invalid lifetime value of '$s->{lifetime}'" unless $number && $unit;
  
  my $expiry;
  if( $unit eq 'S' )
  {
    $expiry = $number;
  }
  elsif( $unit eq 'M' )
  {
    $expiry = $number * 60;
  }
  elsif( $unit eq 'H' )
  {
    $expiry = $number * 60 * 60;
  }
  elsif( $unit eq 'D' )
  {
    $expiry = $number * 60 * 60 * 24;
  }# end if()
  
  $s->{expiry} = $expiry;
  1;
}# end init()


sub set
{
  my ($s, $key, $value) = @_;
  
  $s->memd->set( $key, $value, $s->{expiry} );
}# end set()


sub get
{
  my ($s, $key) = @_;
  
  $s->memd->get( $key );
}# end get()


sub delete
{
  my ($s, $key) = @_;
  
  $s->memd->delete( $key );
}# end delete()


sub clear
{
  my ($s) = @_;
  
  $s->memd->flush_all;
}# end clear()

1;# return true:

=pod

=head1 NAME

Class::DBI::Lite::CacheManager::Memcached - Cache via memcached.

=head1 SYNOPSIS

  package app::user;
  
  use strict;
  use warnings 'all';
  use base 'app::model';
  use Class::DBI::Lite::CacheManager::Memcached;
  
  __PACKAGE__->set_up_table('users');
  
  __PACKAGE__->set_cache(
    Class::DBI::Lite::CacheManager::Memcached->new(
      lifetime        => '30s',
      class           => __PACKAGE__,
      servers         => ['127.0.0.1:11211'],
      do_cache_search => 1,
    )
  );
  
  __PACKAGE__->cache->cache_searches_containing(qw(
    email
    password
  ));

Then, someplace else...

  # This will be cached...
  my ($user) = app::user->search(
    email     => 'alice@wonderland.net',
    password  => 'whiterabbit',
  );

...later...

  # This won't hit the database - the result will come from the cache instead:
  my ($user) = app::user->search(
    email     => 'alice@wonderland.net',
    password  => 'whiterabbit',
  );

A create, update or delete invalidates the cache:

  $user->delete; # Cache is emptied now.

=head1 DESCRIPTION

C<Class::DBI::Lite::CacheManager::Memcached> uses L<Cache::Memcached> to temporarily
store the results of (presumably) frequent database searches for faster lookup.

So, if your data requirements are such that you find objects of a specific class are getting called
up frequently enough to warrant caching - you can now do that on a per-class basis.

You can even specify the kinds of search queries that should be cached.

You can specify the length of time that cached data should be available.

B<NOTE:> More documentation and complete examples TBD.

=head1 AUTHOR

Copyright John Drago <jdrago_999@yahoo.com>.  All rights reserved.

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the
same terms as perl itself.

=cut

