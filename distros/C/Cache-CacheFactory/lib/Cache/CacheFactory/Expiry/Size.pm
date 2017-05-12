###############################################################################
# Purpose : Cache Size Expiry Policy Class.
# Author  : Sam Graham
# Created : 25 Jun 2008
# CVS     : $Id: Size.pm,v 1.9 2010-02-16 12:25:41 illusori Exp $
###############################################################################

package Cache::CacheFactory::Expiry::Size;

use warnings;
use strict;

use Scalar::Util;

use Cache::Cache;
use Cache::BaseCache;

use Cache::CacheFactory;
use Cache::CacheFactory::Expiry::Base;

use base qw/Cache::CacheFactory::Expiry::Base/;

$Cache::CacheFactory::Expiry::Size::VERSION = '1.10';

@Cache::CacheFactory::Expiry::Size::EXPORT_OK = qw/$NO_MAX_SIZE/;

my ( $use_devel_size );

BEGIN
{
    #  TODO: check for configurations with known Devel::Size issues?
    #  See if we have Devel::Size available.  We don't make it a requirement
    #  because it doesn't seem to work with 5.6 perls.
    eval "use Devel::Size";
    $use_devel_size = 1 unless $@;
}

sub read_startup_options
{
    my ( $self, $param ) = @_;

    $self->{ max_size } = $param->{ max_size }
        if exists $param->{ max_size };
    $self->{ no_devel_size } = $param->{ no_devel_size }
        if exists $param->{ no_devel_size };
    $self->{ no_overrule_memorycache_size } =
        $param->{ no_overrule_memorycache_size }
        if exists $param->{ no_overrule_memorycache_size };
    $self->{ no_cache_cache_size_during_purge } =
        $param->{ no_cache_cache_size_during_purge }
        if exists $param->{ no_cache_cache_size_during_purge };

    $self->{ max_size } = $Cache::CacheFactory::NO_MAX_SIZE
        unless defined $self->{ max_size };
}

sub set_object_validity
{
    my ( $self, $key, $object, $param ) = @_;

}

sub set_object_pruning
{
    my ( $self, $key, $object, $param ) = @_;

}

sub using_devel_size
{
    my ( $self ) = @_;

    return( 1 ) if $use_devel_size and not $self->{ no_devel_size };
    return( 0 );
}

sub guestimate_size
{
    my ( $self, $data ) = @_;
    my ( $totalsize, @queue, %seen );

    return( Devel::Size::total_size( $data ) )
        if $self->using_devel_size();

    #  Fallback in case we're on a system without Devel::Size.
    #  These are highly invented numbers just to give something
    #  better than that in Cache::MemoryCache.
    #  ie: the result may be wrong but it should at least be
    #  somewhat consistently proportional to the right value.

    $totalsize = 0;
    %seen      = ();
    @queue     = ( $data );

    while( @queue )
    {
        my ( $item, $type );

        $item = shift( @queue );
        $type = Scalar::Util::reftype( $item );

        #  Each value has some overhead, let's say twenty bytes,
        #  this is total invention on my part but seems roughly
        #  what Devel::Size is telling me. :)
        $totalsize += 20;

        if( !defined( $type ) )
        {
            #  Yep, wrong if it's a number, tough.
            $totalsize += length( $item );
        }
        else
        {
            #  Only count size of contents of circular references the once.
            next if $seen{ $item }++;
            if( $type eq 'ARRAY' )
            {
                push @queue, @{$item};
            }
            elsif( $type eq 'HASH' )
            {
                push @queue, keys( %{$item} ), values( %{$item} );
            }
            else
            {
                #  HellifIknow.
            }
        }
    }

    return( $totalsize );
}

sub overrule_size
{
    my ( $self, $storage ) = @_;
    my ( $totalsize );

    $totalsize = 0;
    #  Get every object in the cache, not expensive at all, nooooo. :)
    foreach my $key ( $storage->get_keys() )
    {
        my ( $ob );

        $ob = $storage->get_object( $key );
        $totalsize += $self->guestimate_size( $ob );
    }

    return( $totalsize );
}

sub should_keep
{
    my ( $self, $cache, $storage, $policytype, $object ) = @_;
    my ( $cachesize, $itemsize );

    return( 1 )
        if $self->{ max_size } == $Cache::CacheFactory::NO_MAX_SIZE;

    if( not $self->{ no_overrule_memorycache_size } and
        $storage->isa( 'Cache::MemoryCache' ) )
    {
        $cachesize =
            $self->{ _cache_size } || $self->overrule_size( $storage );
        $itemsize = $self->guestimate_size( $object )
            if exists $self->{ _cache_size };
    }
    else
    {
        $cachesize = $self->{ _cache_size } || $storage->size();
        $itemsize = $object->get_size()
            if exists $self->{ _cache_size };
    }

    return( 1 ) if $cachesize <= $self->{ max_size };

    #  We're assuming that a remove will be triggered and succeed
    #  this is potentially risky, but probably ok.
    $self->{ _cache_size } -= $itemsize if exists $self->{ _cache_size };
    return( 0 );
}

sub pre_purge_hook
{
    my ( $self, $cache ) = @_;

    return( 0 )
        if $self->{ max_size } == $Cache::CacheFactory::NO_MAX_SIZE;

    return( $self->SUPER::pre_purge_hook( $cache ) );
}

sub pre_purge_per_storage_hook
{
    my ( $self, $cache, $storage ) = @_;

    #  Locally cache the cache-size so we don't keep recalculating it
    #  for each key, this is a bit of a hack and assumes nothing but
    #  the purge is going to change the size while we're purging.
    #  If something else does, we might over or under prune.
    #  Without locking this will always be a risk for shared caches
    #  anyway.
    unless( $self->{ no_cache_cache_size_during_purge } )
    {
        if( not $self->{ no_overrule_memorycache_size } and
            $storage->isa( 'Cache::MemoryCache' ) )
        {
            $self->{ _cache_size } = $self->overrule_size( $storage );
        }
        else
        {
            $self->{ _cache_size } = $storage->size();
        }
    }

    return( $self->SUPER::pre_purge_per_storage_hook( $cache, $storage ) );
}

sub post_purge_per_storage_hook
{
    my ( $self, $cache, $storage ) = @_;

    #  Clear our local caching of the cache size.
    delete $self->{ _cache_size };
    $self->SUPER::post_purge_per_storage_hook( $cache, $storage );
}

sub limit_size
{
    my ( $self, $cache, $size ) = @_;
    my ( $old_max_size );

    $old_max_size = $self->{ max_size };
    $self->{ max_size } = $size;

    $self->purge( $cache );

    $self->{ max_size } = $old_max_size;    
}

1;

=pod

=head1 NAME

Cache::CacheFactory::Expiry::Size - Size-based expiry policy for Cache::CacheFactory.

=head1 DESCRIPTION

L<Cache::CacheFactory::Expiry::Size>
is a size-based expiry (pruning and validity) policy for
L<Cache::CacheFactory>.

It provides similar functionality and backwards-compatibility with
the C<max_size> option of L<Cache::SizeAwareFileCache> and variants.

It's highly recommended that you B<DO NOT> use this policy as a
validity policy, as calculating the size of the contents of the
cache on each read can be quite expensive, and it's semantically
ambiguous as to just what behaviour is intended by it anyway.

Note that in its current implementation L<Cache::CacheFactory::Expiry::Size>
is "working but highly inefficient" when it comes to purging.
It is provided mostly for completeness while a revised version
is being worked on.

=head1 SIZE SPECIFICATIONS

Currently all size values must be specified as numbers and will be
interpreted as bytes. Future versions reserve the right to supply
the size as a string '10 M' for ease of use, but this is not currently
implemented.

=head1 STARTUP OPTIONS

The following startup options may be supplied to 
L<Cache::CacheFactory::Expiry::Size>,
see the L<Cache::CacheFactory> documentation for
how to pass options to a policy.

=over

=item max_size => $size

This sets the maximum size that the cache strives to keep under,
any items that take the cache over this size will be pruned (for
a pruning policy) at the next C<< $cache->purge() >>.

See the L</"SIZE SPECIFICATIONS"> section above for details on
what values you can pass in as C<$size>.

You can also use C<Cache::CacheFactory::$NO_MAX_SIZE> to indicate
that there is no size limit automatically applied, this is generally
a bit pointless with a 'size' policy unless you are going to call
C<limit_size()> manually every so often.

Note that by default pruning policies are not immediately enforced,
they are only applied when a C<< $cache->purge() >> occurs. This
means that it is possible (likely even) for the size of the cache
to exceed C<max_size> at least on a temporary basis. When the next
C<< $cache->purge() >> occurs, the cache will be reduced back down
below C<max_size>.

If you make use of the C<auto_purge_on_set> option to
L<Cache::CacheFactory>, you'll cause a C<< $cache->purge() >>
on a regular basis depending on the value of C<auto_purge_interval>.

However, even with the most aggressive values of C<auto_purge_interval>
there will still be a best-case scenario of the cache entry being
written to the cache, taking it over C<max_size>, and the purge
then reducing the cache to or below C<max_size>. This is essentially
unavoidable since it's impossible to know the size an entry will
take in the cache until it has been written.

Also note that for each C<purge()> the cache will need to call
C<size()> once (or more if C<no_cache_cache_size_during_purge> is set),
which on most storage policies will involve inspecting
the size of every key in that namespace. Needless to say this can
be quite an expensive operation.

With these points in mind you may consider setting C<max_size> to
C<$NO_MAX_SIZE> and manually calling C<< $cache->limit_size( $size ) >>
periodically at a time that's under your control.

=item no_cache_cache_size_during_purge => 0 | 1

By default, to reduce the number of calls to C<< $storage->size() >>
during a purge, the size of the cache will be stored locally at
the start of a purge and estimated as keys are purged.

For the most part this is reasonable behaviour, however if the
estimated reduction from deleting a key is wrong (this "shouldn't
happen") the size estimate will be inaccurate and the cache will
either be overpurged or underpurged.

The other issue however is with shared caches, since there is no
locking during a purge, it's possible for another thread or process
to add or remove from the cache (or even C<purge()>), altering the
size of the cache during the purge, and this will not be noticed,
resulting in either an overpurge or an underpurge.

Neither of these cases will cause a problem for the majority of
applications (or even occur in the first place), however you can
disable this caching of C<size()> by setting
C<no_cache_cache_size_during_purge> to a true value
if it does cause you problems.

Please note however that this will mean that C<size()> will need
to be called when every key is inspected (not just removed!) for
pruning. Read the notes for C<max_size> above as this is likely to
have a dramatic performance degredation.

=item no_overrule_memorycache_size => 0 | 1

By default L<Cache::CacheFactory::Expiry::Size> will attempt a
workaround for the problems mentioned in "Memory cache inaccuracies"
in the L</"KNOWN ISSUES AND BUGS"> section.

If this behaviour is undesirable, supply a true value to the
C<no_overrule_memorycache_size> option.

=item no_devel_size => 0 | 1

If the above workaround is in effect it will attempt to use L<Devel::Size>
if it is available, since this module delves into the internals of perl
it can be fragile on perl version changes and you may wish to disable
it if this is causing you problems, to do that set the C<no_devel_size>
option to a true value.

=back

=head1 STORE OPTIONS

There are no per-key options for this policy.

=head1 METHODS

You shouldn't need to call any of these methods directly.

=over

=item $size = $policy->overrule_size( $storage );

This method is used to overrule the usual C<< $storage->size() >>
method when comparing against C<max_size>, it attempts to
analyze every object in the cache and sum their memory footprint
via C<< $policy->guestimate_size() >>.

By default this is used when trying to workaround issues with
the C<size()> method of L<Cache::MemoryCache>.

=item $size = $policy->guestimate_size( $data );

This method provides a rough (very rough sometimes) estimate of
the memory footprint of the data structure C<$data>.

This is used internally by the L<Cache::MemoryCache> workaround.

=item $boolean = $policy->using_devel_size();

Return true or false depending on whether this policy instance
will use Devel::Size in C<< $policy->guestimate_size() >>.

NOTE: this does not imply that C<< $policy->guestimate_size() >>
will itself be being used.

Mostly this is a debug method is so I can write saner regression
tests.

=item $policy->limit_size( $cache, $size );

Called by C<< $cache->limit_size() >>, this does a one-time prune
of the cache to C<$size> size or below.

=back

=head1 KNOWN ISSUES AND BUGS

=over

=item Memory cache inaccuracies

Due to the way that L<Cache::MemoryCache> and L<Cache::SharedMemoryCache>
implement the C<size()> method, the values returned do not actually
reflect the memory used by a cache entry, in fact it's likely to return
a somewhat arbitrary value linear to the number of entries in the cache
and independent of the size of the data in the entries.

This means that a 'size' pruning policy applied to storage policies of
'memory' or 'sharedmemory' would not keep the size of the cache
under C<max_size> bytes.

So, by default L<Cache::CacheFactory::Expiry::Size> will ignore and overrule
the value of C<< Cache::MemoryCache->size() >> or
C<< CacheSharedMemoryCache->size() >> when checking against C<max_size> and
will attempt to use its own guestimate of the memory taken up.

To do this it will make use of L<Devel::Size> if available, or
failing that use a very simplistic calculation that should at least be
proportional to the size of the data in the cache rather than the number
of entries.

Since L<Devel::Size> doesn't appear to be successfully tested on
perls of 5.6 vintage or earlier and the bug only effects memory
caches, L<Devel::Size> hasn't been made a requirement of this module.

This may all be considered as a bug, or at the least a gotcha.

=back

=head1 SEE ALSO

L<Cache::CacheFactory>, L<Cache::Cache>, L<Cache::SizeAwareFileCache>,
L<Cache::SizeAwareCache>, L<Cache::CacheFactory::Object>,
L<Cache::CacheFactory::Expiry::Base>

=head1 AUTHORS

Original author: Sam Graham <libcache-cachefactory-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 COPYRIGHT

Copyright 2008-2010 Sam Graham.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
