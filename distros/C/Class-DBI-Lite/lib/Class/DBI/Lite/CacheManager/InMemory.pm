
package Class::DBI::Lite::CacheManager::InMemory;

use strict;
use warnings 'all';
use base 'Class::DBI::Lite::CacheManager';
use Carp 'confess';


sub defaults
{
  return (
    lifetime  => '30s',
    class     => undef,
  );
}# end defaults()


sub class { shift->{class} }


sub init
{
  my ($s) = @_;
  
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
  $s->{cache} = { };
  1;
}# end init()


sub set
{
  my ($s, $key, $value) = @_;
  
  my $exp = time() + $s->{expiry};
  $s->{cache}{$key} = { expires => $exp, value => $value };
}# end set()


sub get
{
  my ($s, $key) = @_;

  return unless exists($s->{cache}{$key}) && $s->{cache}{$key}->{expires} > time();
  return $s->{cache}{$key}->{value};
}# end get()


sub delete
{
  my ($s, $key) = @_;

  delete( $s->{cache}{$key} );
}# end delete()


sub clear
{
  my ($s) = @_;
  
  $s->{cache} = { };
}# end clear()

1;# return true:

=pod

=head1 NAME

Class::DBI::Lite::CacheManager::InMemory - Cache in RAM.

=head1 SYNOPSIS

  package app::user;
  
  use strict;
  use warnings 'all';
  use base 'app::model';
  use Class::DBI::Lite::CacheManager::InMemory;
  
  __PACKAGE__->set_up_table('users');
  
  __PACKAGE__->set_cache(
    Class::DBI::Lite::CacheManager::Memcached->new(
      lifetime        => '30s',
      class           => __PACKAGE__,
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

...later - within 30 seconds...

  # This won't hit the database - the result will come from the cache instead:
  my ($user) = app::user->search(
    email     => 'alice@wonderland.net',
    password  => 'whiterabbit',
  );

A create, update or delete invalidates the cache:

  $user->delete; # Cache is emptied now.

=head1 DESCRIPTION

C<Class::DBI::Lite::CacheManager::InMemory> will store the results of searches
in RAM for a specific length of time.  This is helpful if you find that your
application's performance is suffering because of oft-repeated queries.

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

