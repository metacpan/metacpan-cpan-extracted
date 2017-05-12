package Catalyst::Plugin::UploadProgress::Role::Request;
use Moose::Role;
use namespace::autoclean;

has _cache => (
    required => 1,
    handles => [qw/ get set /],
);

around 'prepare_body_chunk' => sub {
    my ( $orig, $self, $chunk, @args ) = @_;

    $self->$orig($chunk, @args);

    my $id = $self->query_parameters->{progress_id};

    if ( $id ) {
        # store current progress in cache
        my $progress = $self->get( 'upload_progress_' . $id );

        if ( !defined $progress ) {
            # new upload
            $progress = {
                size     => $self->_body->content_length,
                received => length $chunk,
            };

            $self->set( 'upload_progress_' . $id, $progress );
        }
        else {
            $progress->{received} += length $chunk;

            $self->set( 'upload_progress_' . $id, $progress );
        }
    }
};

1;

=head1 NAME

Catalyst::Plugin::UploadProgress::Role::Request - Request class role for Catalyst::Plugin::UploadProgress

=head1 DESCRIPTION

Updates the C<upload_progress_XXXX> cache key whenever a body chunk is received for the upload,
so that the state of the upload is persisted and can be retrieved by the main plugin.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

