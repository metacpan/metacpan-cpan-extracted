package Blosxom::Plugin::Web::Request::Upload;
use strict;
use warnings;
use File::Spec::Unix;

sub new {
    my ( $class, %args ) = @_;

    my %header;
    if ( my $header = delete $args{header} ) {
        my @fields = map { lc } keys %{ $header };
        @header{ @fields } = values %{ $header };
    }

    my %self = (
        header => \%header,
        fh     => delete $args{fh},
        path   => delete $args{path},
    );

    bless \%self, $class;
}

sub path { shift->{path} }

sub fh       { $_[0]->{fh}    }
sub size     { -s $_[0]->{fh} }
sub filename { "$_[0]->{fh}"  }

sub content_type { shift->{header}->{'content-type'} }

sub header {
    my ( $self, $field ) = @_;
    $field =~ tr/_A-Z/-a-z/;
    $self->{header}->{$field};
}

sub basename {
    my $self = shift;
    ( my $basename = $self->filename ) =~ s{\\}{/}g;
    $basename = ( File::Spec::Unix->splitpath($basename) )[2];
    $basename =~ s{[^\w\.-]+}{_}g;
    $basename;
}

package Fh; # See CGI.pm

sub file {
    require IO::File;
    IO::File->new_from_fd( fileno $_[0], '<' );
}

1;

__END__

=head1 NAME

Blosxom::Plugin::Request::Upload - Handles file upload requests

=head1 SYNOPSIS

  # $request is Blosxom::Plugin::Request
  my $upload = $request->upload( 'field' );

  $upload->size;
  $upload->path;
  $upload->content_type:
  $upload->fh;
  $upload->basename;

=head1 DESCRIPTION

Handles file upload requests.

=head2 METHODS

=over 4

=item $upload->size

Returns the size of uploaded file in bytes.

=item $upload->fh

Returns a read-only file handle on the temporary file.

  my $fh = $upload->fh;

  # Upgrade to IO::Handle
  my $handle = $fh->handle;

  # Upgrade to IO::File handle
  my $file = $fh->file;

=item $upload->path

Returns the path to the temporary file where uploaded file is saved.

=item $upload->content_type

Returns the content type of the uploaded file.

=item $upload->filename

Returns the original filename in the client.

=item $upload->basename

Returns basename for C<filename>.

=item $upload->header

=back

=head1 SEE ALSO

L<Blosxom::Plugin::Request>, L<Plack::Request::Upload>

=head1 AUTHOR

Ryo Anazawa

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlatistic>.

=cut
