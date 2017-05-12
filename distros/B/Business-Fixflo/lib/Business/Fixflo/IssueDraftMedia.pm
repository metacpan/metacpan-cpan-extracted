package Business::Fixflo::IssueDraftMedia;

=head1 NAME

Business::Fixflo::IssueDraftMedia

=head1 DESCRIPTION

A class for a fixflo issue draft media, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;

extends 'Business::Fixflo::Resource';
with 'Business::Fixflo::Utils';

=head1 ATTRIBUTES

    Id
    IssueDraftId
    Url
    ContentType
    ShortDesc
	EncodedByteData

=cut

has [ qw/
    Id
    IssueDraftId
    Url
    ContentType
    ShortDesc
	EncodedByteData
/ ] => (
    is => 'rw',
);

=head1 Operations on a issue draft media

=head2 create

Creates an issue draft media in the Fixflo API

=head2 download

Gets the binary content of the issue draft media.

=head2 delete

Deletes the issue draft media.

=cut

sub create {
    my ( $self,$update ) = @_;

    $self->SUPER::_create( $update,'IssueDraftMedia',sub {
        my ( $self ) = @_;

        $self->Id or $self->Id( undef ); # force null in JSON request

        return { $self->to_hash };
    } );
}

sub download {
    my ( $self ) = @_;

    Business::Fixflo::Exception->throw({
        message  => "Can't download IssueDraftMedia if Id is not set",
    }) if ! $self->Id;

    return $self->client->api_get( 'IssueDraftMedia/' . $self->Id . '/Download' )
}

sub delete {
    my ( $self ) = @_;

    Business::Fixflo::Exception->throw({
        message  => "Can't delete IssueDraftMedia if Id is not set",
    }) if ! $self->Id;

    my $post_data = { Id => $self->Id };

    return $self->_parse_envelope_data(
        $self->client->api_post( 'IssueDraftMedia/Delete',$post_data )
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
