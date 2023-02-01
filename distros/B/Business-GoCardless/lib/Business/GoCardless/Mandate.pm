package Business::GoCardless::Mandate;

=head1 NAME

Business::GoCardless::Mandate

=head1 DESCRIPTION

A class for a gocardless mandate, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    created_at
    consent_parameters
    id
    links
    metadata
    next_possible_charge_date
    payments_require_approval
    reference
    scheme
    status
    verified_at
    
=cut

has [ qw/
    created_at
    consent_parameters
    id
    links
    metadata
    next_possible_charge_date
    payments_require_approval
    reference
    scheme
    status
    verified_at
/ ] => (
    is => 'rw',
);


=head1 Operations on a mandate

=head2 cancel

    $Mandate->cancel;

=head2 update

    $Mandate->update( %params );

note that you can only update the metadata on a mandate, so you must pass the params
hash as something that looks like:

    %params = ( metadata => { ... } );

=cut

sub cancel { shift->_operation( undef,'api_post',undef,'actions/cancel' ); }

sub update {
    my ( $self,%params ) = @_;

    return $self->client->api_put(
        sprintf( $self->endpoint,$self->id ),
        { mandates => { %params } },
    );
}

=head1 Status checks on a mandate

    pending_customer_approval
    pending_submission
    submitted
    active
    failed
    cancelled
    expired

    if ( $Mandate->failed ) {
        ...
    }

=cut

sub pending_customer_approval { return shift->status eq 'pending_customer_approval' }
sub pending_submission        { return shift->status eq 'pending_submission' }
sub submitted                 { return shift->status eq 'submitted' }
sub active                    { return shift->status eq 'active' }
sub failed                    { return shift->status eq 'failed' }
sub cancelled                 { return shift->status eq 'cancelled' }
sub expired                   { return shift->status eq 'expired' }

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
