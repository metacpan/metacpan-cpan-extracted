###############################################################################
# Purpose : Cache LastModified Expiry Policy Class.
# Author  : Sam Graham
# Created : 25 Jun 2008
# CVS     : $Id: LastModified.pm,v 1.7 2010-02-16 12:25:41 illusori Exp $
###############################################################################

package Cache::CacheFactory::Expiry::LastModified;

use warnings;
use strict;

use Cache::CacheFactory::Expiry::Base;

use base qw/Cache::CacheFactory::Expiry::Base/;

$Cache::CacheFactory::Expiry::LastModified::VERSION = '1.10';

sub read_startup_options
{
    my ( $self, $param ) = @_;

    #  Oh, no startup options.  That's easy.
}

sub _set_object_metadata
{
    my ( $self, $policytype, $key, $object, $param ) = @_;
    my ( $dependencies );

    if( $param->{ dependencies } )
    {
        $dependencies = ref( $param->{ dependencies } ) ?
            $param->{ dependencies } : [ $param->{ dependencies } ];
    }

    #  TODO: warn if files don't exist?

    $object->set_policy_metadata( $policytype, 'lastmodified',
        { dependencies => $dependencies, } );
}

sub set_object_validity
{
    my ( $self, $key, $object, $param ) = @_;

    $self->_set_object_metadata( 'validity', $key, $object, $param );
}

sub set_object_pruning
{
    my ( $self, $key, $object, $param ) = @_;

    $self->_set_object_metadata( 'pruning', $key, $object, $param );
}

sub should_keep
{
    my ( $self, $cache, $storage, $policytype, $object ) = @_;
    my ( $metadata, $dependencies, $timecreated );

    $metadata = $object->get_policy_metadata( $policytype, 'lastmodified' );
    $dependencies = $metadata->{ dependencies };
    $timecreated  = $object->get_created_at();

    return( 1 ) unless $dependencies and $#{$dependencies} > -1;

    foreach my $file ( @{$dependencies} )
    {
        #  TODO: options to cache the stat() calls.
        return( 0 ) unless -e $file and (stat( $file ))[ 9 ] < $timecreated;
    }

    return( 1 );
}

1;

=pod

=head1 NAME

Cache::CacheFactory::Expiry::LastModified - File last-modified date dependencies expiry policy for Cache::CacheFactory.

=head1 DESCRIPTION

L<Cache::CacheFactory::Expiry::LastModified>
is an expiry (pruning and validity) policy for
L<Cache::CacheFactory>.

It provides the ability to prune or invalidate cache entries by
comparing the create time of the entry to the last-modified time
of a list of files (AKA dependencies).

=head1 STARTUP OPTIONS

There are no startup options for
L<Cache::CacheFactory::Expiry::LastModified>.

=head1 STORE OPTIONS

The following options may be set when storing a key, see the
L<Cache::CacheFactory> documentation for
details on how to do this.

=over

=item dependencies => $filename

=item dependencies => [ $filename1, $filename2, ... ]

This marks the cache entry as depending on the provided filenames,
if any of these files are modified after the cache entry is created
the entry is considered invalid or is eligible for pruning.

This is done by comparing the last-modified time (as read via C<stat()>)
to the C<created_at> value for the cache entry, this will normally
be reliable but be aware that some programs (tar for example) will
falsify last-modified times, and it's also possible to manipulate
the C<created_at> time of a cache entry when first storing it.

Also if the process you are using to generate the content from source
is lengthy it is probably best to take a timestamp from before you
read the source files and supply this as C<created_at> value when
doing C<< $cache->set() >> - this will ensure that any modifications
to the source files between the time you read their content and you
stored the generated content will be correctly detected.

For example:

  $time = time();
  $data = expensive_read_and_build_data_from_file( $file );
  $cache->set(
      key          => 'mykey',
      data         => $data,
      created_at   => $time,
      dependencies => $file,
      );

=back

=head1 KNOWN ISSUES AND BUGS

=over

=item C<stat()> is expensive

Calling C<stat()> on a lot of files is quite expensive, especially
if you're doing it repeatedly. There really ought to be a mechanism
to say that you want to cache the results for a period. Ah, if only
someone had written a handy caching module...

This will probably make it into a future release.

=back

=head1 SEE ALSO

L<Cache::CacheFactory>, L<Cache::Cache>, L<Cache::CacheFactory::Object>,
L<Cache::CacheFactory::Expiry::Base>

=head1 AUTHORS

Original author: Sam Graham <libcache-cachefactory-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 COPYRIGHT

Copyright 2008-2010 Sam Graham.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
