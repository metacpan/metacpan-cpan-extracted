package CGI::Application::PhotoGallery::Magick;

=head1 NAME

CGI::Application::PhotoGallery::Magick - Image::Magick-based graphics adaptor

=head1 SYNOPSIS

    use CGI::Application::PhotoGallery::Magick;
    
    my $lib     = CGI::Application::PhotoGallery::Magick->new;
    my $pngdata = $lib->resize( $file, 100 );

=head1 METHODS

=cut

use strict;
use warnings;

use Image::Magick;

our $VERSION = '0.16';

=head2 new( )

creates a new CGI::Application::PhotoGallery::Magick object.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

=head2 resize( $file, $size )

Resizes C<$file> to C<$size>xC<$size> with transparent margins.

=cut

sub resize {
    my $self = shift;
    my $file = shift;
    my $size = shift;

    my $image = $self->load( $file );

    $image->Scale( Geometry => $size . "x$size" );
    $image->Extent(
        Geometry   => $size . "x$size",
        gravity    => 'center',
        background => 'none'
    );

    return $image->ImageToBlob( magick => 'png' );
}

=head2 load( $file )

Loads C<$file> and returns a L<GD::Image>.

=cut

sub load {
    my $self = shift;
    my $file = shift;

    my $image = Image::Magick->new;

    $image->Read( $file );

    return $image;
}

=head2 size( $file )

Returns the width and height of C<$file>.

=cut

sub size {
    my $self = shift;
    my $file = shift;

    my $image = $self->load( $file );

    return $image->Get( 'width', 'height' );
}

=head1 SEE ALSO

=over 4 

=item * L<Image::Magick>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
