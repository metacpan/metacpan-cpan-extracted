package Catalyst::Plugin::Upload::Basename;

use strict;
use Catalyst::Request::Upload;
use File::Spec::Unix;

our $VERSION = '0.01';

{
    package Catalyst::Request::Upload;

    sub basename {
        my $self = shift;

        unless ( $self->{basename} ) {
            
            my $basename = $self->filename;
            $basename =~ s|\\|/|g;
            $basename = ( File::Spec::Unix->splitpath($basename) )[2];
            $basename =~ s|[^\w\.-]+|_|g;

            $self->{basename} = $basename;
        }

        return $self->{basename};
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Upload::Basename - Basename for uploads

=head1 SYNOPSIS

    use Catalyst qw[Upload::Basename];

    if ( my $upload = $c->request->upload('field') ) {
        print $upload->basename;
    }


=head1 DESCRIPTION

Extends C<Catalyst::Request::Upload> with a basename method.

=head1 METHODS

=over 4

=item basename

Returns basename for C<filename>.

=back

=head1 SEE ALSO

L<Catalyst::Request>, L<Catalyst::Request::Upload>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
