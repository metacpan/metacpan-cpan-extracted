package Catalyst::Plugin::Upload::MIME;

use strict;
use Catalyst::Request::Upload;
use File::MimeInfo::Magic ();

our $VERSION = '0.01';

{
    package Catalyst::Request::Upload;

    sub mimetype {
        my $self = shift;

        unless ( $self->{mimetype} ) {
            $self->{mimetype} ||= File::MimeInfo::Magic::magic( $self->tempname );
            $self->{mimetype} ||= File::MimeInfo::Magic::default( $self->tempname );
        }

        return $self->{mimetype};
    }

    sub extension {
        my $self = shift;

        unless ( $self->{extension} ) {
            $self->{extension} = File::MimeInfo::Magic::extensions( $self->mimetype );
        }
        
        return $self->{extension};
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Upload::MIME - MIME type for uploads

=head1 SYNOPSIS

    use Catalyst qw[Upload::MIME];

    if ( my $upload = $c->request->upload('field') ) {
        print $upload->mimetype;
        print $upload->extension;
    }


=head1 DESCRIPTION

Extends C<Catalyst::Request::Upload> with C<MIME type> magic.

=head1 METHODS

=over 4

=item extension

Returns file extension for C<mimetype>.

=item mimetype

Returns C<MIME type> for tempname using magic.

=back

=head1 SEE ALSO

L<File::MimeInfo::Magic>, L<Catalyst::Request>, L<Catalyst::Request::Upload>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
