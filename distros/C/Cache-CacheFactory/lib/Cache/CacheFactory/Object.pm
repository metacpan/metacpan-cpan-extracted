###############################################################################
# Purpose : Extension of Cache::Object.pm to support policy meta-data.
# Author  : Sam Graham
# Created : 24 Jun 2008
# CVS     : $Id: Object.pm,v 1.7 2010-02-16 12:25:41 illusori Exp $
###############################################################################

package Cache::CacheFactory::Object;

use warnings;
use strict;

use base qw/Cache::Object/;

use Storable;

$Cache::CacheFactory::Object::VERSION = '1.10';

sub new_from_old
{
    my ( $class, $old_ob, $param ) = @_;
    my ( $ob );

    $ob = $class->new();
    $ob->initialize(
        $old_ob->get_key(),
        $old_ob->get_data(),
        {
            created_at    => $old_ob->get_created_at(),
            accessed_at   => $old_ob->get_accessed_at(),
            expires_at    => $old_ob->get_expires_at(),
            no_deep_clone => $param->{ no_deep_clone },
        } );
    #  TODO: this should probably be recalculated by the policies?
    $ob->set_size( $old_ob->get_size() );
}

sub initialize
{
    my ( $self, $key, $data, $param ) = @_;

    $self->set_key( $key );

    #  Produce a deep clone fo the data unless we don't need to
    #  or we're asked not to.
    $data = Storable::dclone( $data )
        if ref( $data ) and not $param->{ no_deep_clone };

    #  Set the data.
    $self->set_data( $data );
    #  TODO: weaken ref param handling here?

    #  Overrule default properties if they've been supplied.
    foreach my $property ( qw/created_at accessed_at expires_at/ )
    {
        if( exists( $param->{ $property } ) )
        {
            my ( $method );

            $method = "set_${property}";
            $self->$method( $param->{ $property } );
            delete $param->{ $property };
        }
    }
}

sub set_policy_metadata
{
    my ( $self, $policytype, $policy, $metadata ) = @_;

    $self->{ _Policy_Meta_Data } ||= {};
    $self->{ _Policy_Meta_Data }->{ $policytype } ||= {};
    $self->{ _Policy_Meta_Data }->{ $policytype }->{ $policy } = $metadata;
}

sub get_policy_metadata
{
    my ( $self, $policytype, $policy ) = @_;

    return( $self->{ _Policy_Meta_Data }->{ $policytype }->{ $policy } );
}

1;

__END__

=pod

=head1 NAME

Cache::CacheFactory::Object - the data stored in a Cache::CacheFactory cache.

=head1 DESCRIPTION

L<Cache::CacheFactory::Object> is a subclass extending L<Cache::Object> to
allow for per-policy meta-data needed by L<Cache::CacheFactory>'s policies.

You will not normally need to use this class for anything.

If you are already using L<Cache::Object> then you'll find that
L<Cache::CacheFactory::Object> only extends behaviour, it doesn't
alter existing behaviour.

=head1 SYNOPSIS

 use Cache::CacheFactory::Object;

 my $object = Cache::CacheFactory::Object( );

 $object->set_key( $key );
 $object->set_data( $data );
 $object->set_expires_at( $expires_at );
 $object->set_created_at( $created_at );
 $object->set_policy_metadata( 'expiry', 'time', $metadata );


=head1 METHODS

=over

=item $object = Cache::CacheFactory::Object->new_from_old( $cache_object, [ $param ] );

Construct a new L<Cache::CacheFactory::Object> from a L<Cache::Object>
instance, this is done automatically by L<Cache::CacheFactory> methods
that provide backwards compat.

C<$param> is an optional argument that contains additional parameters
to pass to C<< $object->initialize() >>.

=item $object->initialize( $key, $data, $param );

Initializes the object, this is done seperately from the constructor
to make it easier for people to subclass L<Cache::CacheFactory::Object>
should they need to.

=item $object->set_policy_metadata( $policytype, $policy, $metadata );

Set the meta-data for the given C<$policytype> and C<$policy> to the value
provided in C<$metadata>, usually a hashref.

See the documentation on L<Cache::CacheFactory> for more information
about policy types and policies.

=item $metadata = $object->get_policy_metadata( $policytype, $policy );

Fetch the meta-data stored by C<$policytype> and C<$policy>.

See the documentation on L<Cache::CacheFactory> for more information
about policy types and policies.

=back

All other behaviour is inherited from and documented by L<Cache::Object>.

=head1 SEE ALSO

L<Cache::CacheFactory>, L<Cache::Object>

=head1 AUTHORS

Original author: Sam Graham <libcache-cachefactory-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 COPYRIGHT

Copyright 2008-2010 Sam Graham.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
