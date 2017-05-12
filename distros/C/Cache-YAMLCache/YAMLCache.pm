######################################################################
# $Id: YAMLCache.pm,v 1.2 2005/10/26 16:18:30 nachbaur Exp $
# Copyright (C) 2005 Michael Nachbaur  All Rights Reserved
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either expressed or
# implied. See the License for the specific language governing
# rights and limitations under the License.
######################################################################


package Cache::YAMLCache;


use strict;
use vars qw( @ISA $VERSION );
use Cache::FileCache;
use Cache::CacheUtils qw ( Assert_Defined Build_Path Static_Params );
use Cache::YAMLBackend;

$VERSION = "0.01";

@ISA = qw ( Cache::FileCache );


# by default, the root of the cache is located in 'YAMLCache'.  On a
# UNIX system, this will appear in "/tmp/YAMLCache/"

my $DEFAULT_CACHE_ROOT = "YAMLCache";

sub _Get_Backend
{
  my ( $p_optional_cache_root ) = Static_Params( @_ );

  return new Cache::YAMLBackend( _Build_Cache_Root( $p_optional_cache_root ) );

}


sub _Get_Cache
{
  my ( $p_namespace, $p_optional_cache_root ) = Static_Params( @_ );

  Assert_Defined( $p_namespace );

  if ( defined $p_optional_cache_root )
  {
    return new Cache::YAMLCache( { 'namespace' => $p_namespace,
                                   'cache_root' => $p_optional_cache_root } );
  }
  else
  {
    return new Cache::YAMLCache( { 'namespace' => $p_namespace } );
  }
}



sub _initialize_file_backend
{
  my ( $self ) = @_;

  $self->_set_backend( new Cache::YAMLBackend( $self->_get_initial_root( ),
                                               $self->_get_initial_depth( ),
                                               $self->_get_initial_umask( ) ));
}

1;


__END__

=pod

=head1 NAME

Cache::YAMLCache -- implements the Cache interface.

=head1 DESCRIPTION

The YAMLCache class implements the Cache interface by inheriting
from the Cache::FileCache module and, instead of using the Storable
module for doing cache writes, it saves the data to the filesystem
as YAML data.

=head1 SYNOPSIS

  use Cache::YAMLCache;

  my $cache = new Cache::YAMLCache( { 'namespace' => 'MyNamespace',
                                      'default_expires_in' => 600 } );

  See Cache::Cache and Cache::FileCache for the usage synopsis.

=head1 METHODS

See Cache::Cache for the API documentation, and Cache::FileCache
for information about the methods this object exposes since Cache::YAMLCache
overrides only private methods.

=head1 OPTIONS

See Cache::FileCache for what your available options are.

=head1 PROPERTIES

See Cache::FileCache for default properties.  In fact, see Cache::FileCache for
pretty much everything.

=head1 AUTHOR

Original author: Michael Nachbaur <mike@nachbaur.com>

Last author:     $Author: nachbaur $

Copyright (C) 2005 Michael Nachbaur

=cut
