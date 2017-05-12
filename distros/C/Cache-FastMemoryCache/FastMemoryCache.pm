# ---------------------------------------------------------
# This code is largely based on DeWitt Clinton's
# Cache::MemoryCache.  It relies upon the fact that we have
# ferreted out the calls to Clone_Data().
# ---------------------------------------------------------

package Cache::FastMemoryCache;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.01;

use base qw ( Cache::BaseCache );
use Cache::CacheUtils qw( Assert_Defined Static_Params );
use Cache::FastMemoryBackend;


sub Clear
{
  foreach my $namespace ( _Namespaces( ) )
  {
    _Get_Backend( )->delete_namespace( $namespace );
  }
}


sub Purge
{
  foreach my $namespace ( _Namespaces( ) )
  {
    _Get_Cache( $namespace )->purge( );
  }
}


sub Size
{
  my $size = 0;

  foreach my $namespace ( _Namespaces( ) )
  {
    $size += _Get_Cache( $namespace )->size( );
  }

  return $size;
}


sub _Get_Backend
{
  return new Cache::MemoryBackend( );
}


sub _Namespaces
{
  return _Get_Backend( )->get_namespaces( );
}


sub _Get_Cache
{
  my ( $p_namespace ) = Static_Params( @_ );

  Assert_Defined( $p_namespace );

  return new Cache::MemoryCache( { 'namespace' => $p_namespace } );
}


sub new
{
  my ( $self ) = _new( @_ );

  $self->_complete_initialization( );

  return $self;
}

sub _new
{
  my ( $proto, $p_options_hash_ref ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self = $class->SUPER::_new( $p_options_hash_ref );
  $self->_set_backend( new Cache::FastMemoryBackend( ) );
  return $self;
}


sub set_object
{
  my ( $self, $p_key, $p_object ) = @_;

  my $object =  $p_object; # no clone

  $object->set_size( undef );
  $object->set_key( undef );

  $self->_get_backend( )->store( $self->get_namespace( ), $p_key, $object );
}

1;
__END__

=head1 NAME

Cache::FastMemoryCache - In-memory cache of arbitrary data.

=head1 SYNOPSIS

  use Cache::FastMemoryCache;

  my $cache = new Cache::FastMemoryCache({ 'namespace' => 'MyNamespace' });
  $key = 'xxx';
  $href->{'name'} = 'old name';
  
  $cache->set( $key, $href );   # insert into cache.
  $href->{'name'} = 'new name'; # modify it after insert.

  # Later...

  $href = $cache->get($key);
  print $href->{'name'};        # prints "new name"
  

=head1 DESCRIPTION

Cache::FastMemoryCache is an in-memory cache, implemented as
an extension to the excellent Cache::Cache suite. All cached
items are stored per-process. The cache does not persist
after the process dies.  It is the fastest of all the
Cache::* types because it does not perform deep copying of
data. 

=head1 METHODS

See Cache::Cache for the API.

=head1 CAVEATS

The other Cache::* types  make deep copies of data before
inserting it into the cache -- FastMemoryCache does not make
copies. 

The example in the SYNOPSIS section of this
manual prints "new name" with FastMemoryCache, but prints
"old name" with other cache types!

=head1 AUTHOR

John Millaway E<lt>millaway@acm.orgE<gt>
    
(Based heavily on DeWitt Clinton's Cache::MemoryCache
module.)

=head1 SEE ALSO

Cache::Cache, Cache::MemoryCache.

=cut
