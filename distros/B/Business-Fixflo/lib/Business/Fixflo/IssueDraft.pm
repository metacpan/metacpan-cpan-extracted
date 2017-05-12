package Business::Fixflo::IssueDraft;

=head1 NAME

Business::Fixflo::IssueDraft

=head1 DESCRIPTION

A class for a fixflo issue draft, extends L<Business::Fixflo::Issue>

=cut

use strict;
use warnings;

use Moo;

extends 'Business::Fixflo::Issue';
with 'Business::Fixflo::Utils';

use Business::Fixflo::Address;

=head1 ATTRIBUTES

    Updated
    IssueDraftMedia
    IssueTitle
    FirstName # note inconsistent with Issue (Firstname)
              # however Firstname will be set using an around modifier

=cut

has [ qw/
    Updated
    IssueDraftMedia
    IssueTitle
    PropertyId
    ExternalPropertyRef
    FirstName
/ ] => (
    is => 'rw',
);

=head1 Operations on a issue draft

=head2 create

Creates an issue draft in the Fixflo API

=head2 update

Updates an issue draft in the Fixflo API - will throw an exception if the Id
is not set

=head2 commit

Commits the issue draft, returning a Business::Fixflo::Issue object

=head2 delete

Deletes the issue draft.

=cut

# IssueDraft has Firstname, whereas Issue has Firstname, so let's set
# Firstname whenever FirstName is set so we can just use Firstname as
# an accessor to be consistent
after FirstName => sub {
    my ( $self,$value ) = @_;
    $self->Firstname( $value );
    return;
};

sub create {
    my ( $self,$update ) = @_;

    $self->SUPER::_create( $update,'IssueDraft',sub {
        my ( $self ) = @_;

        $self->Id or $self->Id( undef ); # force null in JSON request

        my $post_data = { $self->to_hash };

        if ( $self->Address ) {
            $post_data->{Address} = ref( $self->Address ) eq 'HASH'
                ? $self->Address
                : { $self->Address->to_hash };
        }

        return $post_data;
    } );
}

sub commit {
    my ( $self ) = @_;

    Business::Fixflo::Exception->throw({
        message  => "Can't commit IssueDraft if Id is not set",
    }) if ! $self->Id;

    my $post_data = { Id => $self->Id };

    return Business::Fixflo::Issue->new(
        client => $self->client,
    )->_parse_envelope_data(
        $self->client->api_post( 'IssueDraft/Commit',$post_data )
    );
}

sub delete {
    my ( $self ) = @_;

    Business::Fixflo::Exception->throw({
        message  => "Can't delete IssueDraft if Id is not set",
    }) if ! $self->Id;

    my $post_data = { Id => $self->Id };

    return $self->_parse_envelope_data(
        $self->client->api_post( 'IssueDraft/Delete',$post_data )
    );
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo

=cut

1;

# vim: ts=4:sw=4:et
