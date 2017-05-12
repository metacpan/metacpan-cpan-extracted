###############################################################################
# Purpose : Cache Time Expiry Policy Class.
# Author  : Sam Graham
# Created : 25 Jun 2008
# CVS     : $Id: Time.pm,v 1.8 2010-02-16 12:25:41 illusori Exp $
###############################################################################

package Cache::CacheFactory::Expiry::Time;

use warnings;
use strict;

use Cache::Cache;
use Cache::BaseCache;

use Cache::CacheFactory::Expiry::Base;

use base qw/Cache::CacheFactory::Expiry::Base/;

$Cache::CacheFactory::Expiry::Time::VERSION = '1.10';

sub read_startup_options
{
    my ( $self, $param ) = @_;

    $self->set_default_expires_in( $param->{ default_expires_in } )
        if exists( $param->{ default_expires_in } );

    $self->{ default_prune_after } = $param->{ default_prune_after }
        if exists( $param->{ default_prune_after } );
    $self->{ default_valid_until } =
        ( $param->{ default_valid_until } eq 'forever' ) ?
        $Cache::Cache::EXPIRES_NEVER : $param->{ default_valid_until }
        if exists( $param->{ default_valid_until } );
}

sub set_default_expires_in
{
    my ( $self, $default_expires_in ) = @_;

    #  Compat with Cache::Cache.
    $self->{ default_prune_after } = $default_expires_in;
    $self->{ default_valid_until } = $default_expires_in;
}

sub get_default_expires_in
{
    my ( $self ) = @_;

    return( $self->{ default_prune_after } || $self->{ default_valid_until } );
}

sub set_object_validity
{
    my ( $self, $key, $object, $param ) = @_;
    my ( $valid_until );

    #  Failover in order:
    #    supplied valid_until param
    #    supplied expires_in param
    #    default valid_until param (includes default expires_in)
    #    EXPIRES_NEVER as last resort.
    $valid_until = $self->{ default_valid_until }
        if exists( $self->{ default_valid_until } );
    $valid_until = $param->{ expires_in }
        if exists( $param->{ expires_in } );
    $valid_until =
        ( $param->{ valid_until } eq 'forever' ) ?
        $Cache::Cache::EXPIRES_NEVER : $param->{ valid_until }
        if exists( $param->{ valid_until } );

    $valid_until = Cache::BaseCache::Build_Expires_At(
        $object->get_created_at(),
        $Cache::Cache::EXPIRES_NEVER,
        $valid_until );

    $object->set_policy_metadata( 'validity', 'time',
        { valid_until => $valid_until, } );
}

sub set_object_pruning
{
    my ( $self, $key, $object, $param ) = @_;
    my ( $prune_after );

    #  Failover in order:
    #    supplied prune_after param
    #    supplied expires_in param
    #    default prune_after param (includes default expires_in)
    #    EXPIRES_NEVER as last resort.
    $prune_after = $self->{ default_prune_after }
        if exists( $self->{ default_prune_after } );
    $prune_after = $param->{ expires_in }
        if exists( $param->{ expires_in } );
    $prune_after = $param->{ prune_after }
        if exists( $param->{ prune_after } );

    $prune_after = Cache::BaseCache::Build_Expires_At(
        $object->get_created_at(),
        $Cache::Cache::EXPIRES_NEVER,
        $prune_after );

    $object->set_policy_metadata( 'pruning', 'time',
        { prune_after => $prune_after, } );
}

sub should_keep
{
    my ( $self, $cache, $storage, $policytype, $object ) = @_;
    my ( $metadata, $expires, $when );

    $metadata = $object->get_policy_metadata( $policytype, 'time' );
    $expires  = $metadata->{ valid_until } || $metadata->{ prune_after };
    $when     = time();

    return( 1 ) unless defined( $expires );
    return( 0 ) if $expires eq $Cache::Cache::EXPIRES_NOW;
    return( 1 ) if $expires eq $Cache::Cache::EXPIRES_NEVER;
    return( 0 ) if $when >= $expires;
    return( 1 );
}

1;

=pod

=head1 NAME

Cache::CacheFactory::Expiry::Time - Time-based expiry policy for Cache::CacheFactory.

=head1 DESCRIPTION

L<Cache::CacheFactory::Expiry::Time>
is a time-based expiry (pruning and validity) policy for
L<Cache::CacheFactory>.

It provides similar functionality and backwards-compatibility with
the C<$expires_in> and C<$default_expires_in> properties of
L<Cache::Cache>.

=head1 INTERVAL SPECIFICATIONS

You can use any of the syntaxes provided by L<Cache::Cache> to
specify an interval for expiry times, for example:

  $Cache::Cache::EXPIRES_NEVER
  $Cache::Cache::EXPIRES_NOW
  '4 seconds'
  '1 m'
  'now'
  'never'

For a full list take a look at the C<set()> section of the
L<Cache::Cache> documentation.

=head1 STARTUP OPTIONS

The following startup options may be supplied to 
L<Cache::CacheFactory::Expiry::Time>,
see the L<Cache::CacheFactory> documentation for
how to pass options to a policy.

=over

=item default_prune_after => $interval

For a pruning policy this sets the default interval after which an
item becomes eligible to be pruned.

=item default_valid_until => $interval

For a validity policy this sets the default time interval after
which an item should be considered invalid.

=item default_expires_in => $interval

This option provides backwards-compatibility with L<Cache::Cache>,
it sets C<default_prune_after> for pruning policies and
C<default_valid_until> for validity policies.

=back

=head1 STORE OPTIONS

The following options may be set when storing a key, see the
L<Cache::CacheFactory> documentation for
details on how to do this.

=over

=item prune_after => $interval

For a pruning policy this sets the interval after which the
item becomes eligible to be pruned. If not supplied then
the value of C<default_prune_after> in the startup options
will be used.

=item valid_until => $interval

For a validity policy this sets the time interval after
which the item should be considered invalid. If not supplied then
the value of C<default_valid_until> in the startup options
will be used.

=item expires_in => $interval

This option provides backwards-compatibility with L<Cache::Cache>,
it behaves as C<prune_after> for pruning policies and C<valid_until>
for validity policies.

=back

=head1 METHODS

You should generally call these via the L<Cache::CacheFactory> interface
rather than directly.

=over

=item $policy->set_default_expires_in( $default_expires_in );

=item $default_expires_in = $policy->get_default_expires_in();

Set or get the C<default_expires_in> option.

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
