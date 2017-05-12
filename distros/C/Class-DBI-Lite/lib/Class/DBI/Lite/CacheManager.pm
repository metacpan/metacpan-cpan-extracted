
package Class::DBI::Lite::CacheManager;

use strict;
use warnings 'all';
use Carp 'confess';
use Digest::MD5 'md5_hex';

sub new
{
  my ($class, %args) = @_;
  
  my %defaults = (
    __PACKAGE__->defaults,
    $class->defaults
  );
  my %params = (
    %defaults,
    %args,
  );
  
  foreach my $arg ( keys %defaults )
  {
    confess "Required param '$arg' was not provided"
      unless defined( $params{$arg} );
  }# end foreach()
  
  my $s = bless \%args, $class;
  $s->init();
  $s->auto_setup();
  return $s;
}# end new()

sub init { }

sub defaults {(
  do_auto_setup     => 1,
  do_cache_retrieve => 1,
  do_cache_search   => 0,
  search_options    => [ ],
  class         => undef
)}

sub do_auto_setup { shift->{do_auto_setup} }

sub do_cache_retrieve { shift->{do_cache_retrieve} }

sub do_cache_search { shift->{do_cache_search} }

sub search_options { @{ shift->{search_options} } }

sub cache_searches_containing
{
  my ($s, @cols) = @_;
  
  my $sig = md5_hex( join ':', sort @cols );
  push @{$s->{search_options}}, $sig;
}# end cache_searches_containing()

sub class { shift->{class} }

sub set;

sub get;

sub delete;

sub clear;

sub auto_setup
{
  my $s = shift;
  
  my $class = $s->class;

  if( $s->do_cache_retrieve )
  {
    $class->add_trigger( before_retrieve => sub {
      my ($s, $id) = @_;
      my $key = $s->get_cache_key( $id );
      $class->cache->get( $key );
    });

    $class->add_trigger( after_retrieve => sub {
      my $s = shift;
      $class->cache->set( $s->get_cache_key => $s->as_hashref );
    });
  }# end if()
  
  if( $s->do_cache_search )
  {
    $class->add_trigger( before_search => sub {
      my ($s, $params) = @_;
      
      my $sig = md5_hex(join ':', sort keys %$params);
      return unless grep { $_ eq $sig } ( $s->cache->search_options );
      
      my $id = md5_hex( join ':', map { "$_=$params->{$_}" } sort keys %$params );
      my $key = $s->get_cache_key( $id );
      
      my $cached = $class->cache->get( $key )
        or return;
      
      my @res = grep { $_ } @{ $cached->{data} };
      return unless @res;
      @res;
    });
    
    $class->add_trigger( after_search => sub {
      my ($s, $params, $result_array) = @_;

      my $sig = md5_hex(join ':', sort keys %$params);
      return unless grep { $_ eq $sig } ( $s->cache->search_options );

      my $id = md5_hex( join ':', map { "$_=$params->{$_}" } sort keys %$params );
      my $key = $s->get_cache_key( $id );

      my @objects = map { $_->as_hashref } @$result_array;
      $class->cache->set( $key => { data => \@objects } );
    });
  }# end if()

  $class->add_trigger( after_create => sub {
    my $s = shift;
    $class->cache->clear();
  });

  $class->add_trigger( after_update => sub {
    my $s = shift;
    $class->cache->clear();
  });

  $class->add_trigger( after_delete => sub {
    my $s = shift;
    $class->cache->clear();
  });
}# end auto_setup()

1;# return true:

=pod

=head1 NAME

Class::DBI::Lite::CacheManager - Base class for NoSQL cache managers.

=head1 SYNOPSIS

You should not use this class directly - use L<Class::DBI::Lite::CacheManager::Memcached>
or L<Class::DBI::Lite::CacheManager::InMemory>.

B<NOTE:> "NoSQL" is "Not Only SQL" - not "No SQL".

=head1 DESCRIPTION

Many - but not all - database queries can be avoided by using a simple cache system.

The CacheManager extentions for L<Class::DBI::Lite> offer the following features:

=over 4

=item * B<Up to 10x increase in speed.>

=item * Per-class caching options - specify different cache parameters on a per-class basis.

=item * Reduced load on the database.

=item * Reduced network traffic.

=back

=head1 SEE ALSO

L<Class::DBI::Lite::CacheManager::Memcached> and L<Class::DBI::Lite::CacheManager::InMemory> for
implementation-specific details.

=head1 AUTHOR

Copyright John Drago <jdrago_999@yahoo.com>.  All rights reserved.

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the
same terms as perl itself.

=cut

