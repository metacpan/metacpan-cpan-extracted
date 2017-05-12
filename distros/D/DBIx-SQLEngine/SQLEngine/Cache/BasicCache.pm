=head1 NAME

DBIx::SQLEngine::Cache::BasicCache - Basic Cache Object

=head1 SYNOPSIS

  use DBIx::SQLEngine::Cache::BasicCache;

  $cache = DBIx::SQLEngine::Cache::BasicCache->new();

  $cache->set( $key, $value );

  $value = $cache->get( $key );

  $cache->clear();

=head1 DESCRIPTION

This package provides a fairly simple cache implementation. 

For a more full-featured cache, use one of the Cache::Cache classes.

=cut

package DBIx::SQLEngine::Cache::BasicCache;

use Carp;

########################################################################

=head1 CACHE INTERFACE

=cut

########################################################################

=head2 Constructor

=over 4

=item new()

=back

=cut

# $cache = DBO::Row::Cache->new( %attrs );
sub new {
  my $class = shift;
  my $cache = bless { @_ }, $class;
  
  $cache->{'__cache_namespace'} ||= caller();
  
  if ( $cache->{'__cache_expiration'} ) {
    $cache->{'__cache_last_expired'} ||= time();
    $cache->{'__cache_expire_freq'} ||= 5;
  }
  
  if ( $cache->{'__cache_item_limit'} ) {
    $cache->{'__cache_last_pruned'} ||= time();
    $cache->{'__cache_prune_freq'} ||= 5;
  }
  
  return $cache;
}

########################################################################

=head2 Accessors

=over 4

=item namespace()

=back

=cut

use Class::MakeMethods::Standard::Hash (
  scalar     => [ qw( 
      __cache_namespace 
      __cache_expiration __cache_last_expired __cache_expire_freq
      __cache_item_limit __cache_last_pruned __cache_prune_freq
  ) ],
);

sub get_namespace { 
  (shift)->__cache_namespace() 
}

########################################################################

=head2 Operations

=over 4

=item get()

=item set()

=item clear()

=back

=cut

########################################################################

# $value_or_undef = $cache->get($key);
sub get {
  my $cache = shift;
  my $key = shift;

  $cache->expire() if ( $cache->{'__cache_expiration'} );
  $cache->prune() if ( $cache->{'__cache_item_limit'} );

  unless ( exists $cache->{ $key } ) {
    debug("RowCache","$cache->{'__cache_namespace'} - cache miss for key $key");
    return undef;
  }
  my $entry = $cache->{ $key };
  if ( $entry->{'expires'} < time() ) {
    debug("RowCache", "$cache->{'__cache_namespace'} - cache time out for key $key");
    $cache->clear( $key );
    return;
  }
  $entry->{'last_used'} = time();
  debug("RowCache", "$cache->{'__cache_namespace'} - cache hit for key $key");
  return $entry->{'data'};
}

# $value = $cache->set($key, $value);
sub set {
  my $cache = shift;
  my $key = shift;
  my $data = shift;
  return if ( not defined $key );
  debug("RowCache", ( exists $cache->{$key} ) 
		? "$cache->{'__cache_namespace'} - overwriting key $key"
		: "$cache->{'__cache_namespace'} - inserting key $key" );
  $cache->{$key} = {
    'data' => $data,
    'last_used' => time(),
    ( $cache->{'__cache_expiration'} ? (
      'expires' => ( time() + $cache->{__cache_expiration} ),
    ) : () ),
  };
  
  return $data;
}

# $cache->clear($key);
sub clear {
  my $cache = shift;
  if ( scalar @_ ) { 
    my $key = shift;
    delete $cache->{ $key };
  } else {
    debug("RowCache", "$cache->{'__cache_namespace'} - cache clear_all" );
    %$cache = map { $_, $cache->{$_} } grep { /^__cache_/ }  keys %$cache;
  }
}

########################################################################

=head2 Expiration and Pruning

=over 4

=item expire()

=item prune()

=back

=cut

# $cache->expire();
sub expire {
  my $cache = shift;
  return unless ( $cache->{'__cache_expiration'} );

  my $time = time();
  return if (
    $cache->{'__cache_last_expired'} + $cache->{'__cache_expire_freq'} > $time 
  );
  $cache->{'__cache_last_expired'} = $time;
  
  foreach my $key ( grep { $_ !~ /^__cache_/ } keys %$cache ) {
    if ( $cache->{ $key }->{'expires'} < $time ) {
      debug("RowCache", "$cache->{'__cache_namespace'} - expiring key $key");
      $cache->clear( $key );
    }
  }
}

# $cache->prune();
sub prune {
  my $cache = shift;
  return unless ( $cache->{'__cache_item_limit'} );

  my $time = time();
  return if (
    $cache->{'__cache_last_pruned'} + $cache->{'__cache_prune_freq'} > $time 
  );
  $cache->{'__cache_last_pruned'} = $time;
  
  my @keys = grep { $_ !~ /^__cache_/ } keys %$cache;
  
  return if ( scalar @keys <= $cache->{'__cache_item_limit'} );
  
  @keys = reverse sort { 
    $cache->{ $a }->{'last_used'} <=> $cache->{ $b }->{'last_used'} 
  } @keys;
  
  foreach my $key ( splice @keys, $cache->{'__cache_item_limit'} ) {
    debug("RowCache", "$cache->{'__cache_namespace'} - pruning key $key");
    $cache->clear( $key );
  }
}

########################################################################

=head2 Logging

=over 4

=item debug()

=back

=cut

sub debug {
  warn @_ 
}

########################################################################

########################################################################

=head1 SEE ALSO

For a more full-featured cache, see L<Cache::Cache>.

For more about the Cache classes, see L<DBIx::SQLEngine::Record::Trait::Cache>.

For more about the Record classes, see L<DBIx::SQLEngine::Record::Class>.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
