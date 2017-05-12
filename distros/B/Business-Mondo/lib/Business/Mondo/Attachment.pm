package Business::Mondo::Attachment;

=head1 NAME

Business::Mondo::Attachment

=head1 DESCRIPTION

A class for a Mondo attachment, extends L<Business::Mondo::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::Mondo::Resource';
with 'Business::Mondo::Utils';

use Types::Standard qw/ :all /;
use DateTime::Format::DateParse;
use Business::Mondo::Exception;

=head1 ATTRIBUTES

The Attachment class has the following attributes (with their type).

    id (Str)
    user_id (Str)
    external_id (Str)
    upload_url (Str)
    file_name (Str)
    file_url (Str)
    file_type (Str)
    created (DateTime)

Note that when when a Str is passed to ->created this will be coerced
to a DateTime object.

=cut

has [ qw/
    id
    user_id
    external_id
    upload_url
    file_name
    file_url
    file_type
/ ] => (
    is  => 'ro',
    isa => Str,
);

has created => (
    is      => 'ro',
    isa     => Maybe[InstanceOf['DateTime']],
    coerce  => sub {
        my ( $args ) = @_;

        if ( ! ref( $args ) ) {
            $args = DateTime::Format::DateParse->parse_datetime( $args );
        }

        return $args;
    },
);

=head1 Operations on an attachment

=head2 upload

Gets the upload_url and file_url for the given file_name and file_type.
Returns a new L<Business::Mondo::Attachment> object with the attributes
file_name, file_type, file_url, and upload_url populated. Note the
required parameters:

    my $file_details = $Attachment->upload(
        file_name => 'foo.png',   # REQUIRED
        file_type => 'image/png', # REQUIRED
    );

TODO: should probably make this easier - upload should actually upload a given
file (file handle?)

=cut

sub upload {
    my ( $self,%params ) = @_;

    $params{file_name} && $params{file_type} ||
        Business::Mondo::Exception->throw({
            message => "upload requires params: file_name, file_type",
        });

    my $data = $self->client->api_post( 'attachment/upload',{
        file_name => $params{file_name},
        file_type => $params{file_type},
    } );

    return $self->new(
        client    => $self->client,
        file_name => $params{file_name},
        file_type => $params{file_type},
        %{ $data },
    );
}

=head2 register

Registers an attachment against an entity (transaction, etc). Returns
a new Business::Mondo::Attachment object with the details populated

    my $file_details = $Attachment->webhooks(
        # the following are REQUIRED if not set on $Attachment
        file_url    => 'http://www.example.com/foo.png',  # REQUIRED
        file_type   => 'image/png',                       # REQUIRED

        # one of the following REQUIRED:
        external_id => $id,
        entity      => $object # Business::Mondo:: - Transaction, Account, etc
    );

=cut

sub register {
    my ( $self,%params ) = @_;

    if ( $params{entity} ) {
        $params{external_id} = $params{entity}->id;
    }

    $params{file_url}  //= $self->file_url;
    $params{file_type} //= $self->file_type;

    $params{external_id} && $params{file_url} && $params{file_type} ||
        Business::Mondo::Exception->throw({
            message => "register requires params: external_id, file_name, file_type",
        });

    my $data = $self->client->api_post( 'attachment/register',{
        external_id => $params{external_id},
        file_url    => $params{file_url},
        file_type   => $params{file_type},
    } );

    return $self->new(
        client     => $self->client,
        file_name  => $self->file_name,
        upload_url => $self->upload_url,
        %{ $data->{attachment} },
    );
}

=head2 deregister

Removes an attachment

    $attachment->deregister;

=cut

sub deregister {
    my ( $self ) = @_;

    return $self->client->api_post( 'attachment/deregister',{
        id => $self->id
    } );
}

=head1 SEE ALSO

L<Business::Mondo>

L<Business::Mondo::Resource>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;

# vim: ts=4:sw=4:et
