package CGI::Application::PhotoGallery::GD;

=head1 NAME

CGI::Application::PhotoGallery::GD - GD-based graphics adaptor

=head1 SYNOPSIS

    use CGI::Application::PhotoGallery::GD;
    
    my $lib     = CGI::Application::PhotoGallery::GD->new;
    my $pngdata = $lib->resize( $file, 100 );

=head1 METHODS

=cut

use strict;
use warnings;

use GD;

our $VERSION = '0.16';

=head2 new( )

creates a new CGI::Application::PhotoGallery::GD object.

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

    my ( $width, $height ) = $image->getBounds();

    my $image2 = new GD::Image( $size, $size );

    $image2->transparent( $image2->colorAllocate( 0, 0, 0 ) );

    my $hnw = int( ( $height * $size / $width ) + 0.5 );
    my $wnh = int( ( $width * $size / $height ) + 0.5 );

    my @arg = ( $image, 0, 0, 0, 0, $size, $size, $width, $height );

    if ( $width > $height ) {
        $arg[ 2 ] = int( ( $size - $hnw ) / 2 + 0.5 );
        @arg[ 5, 6 ] = ( $size, $hnw );
    }
    elsif ( $width < $height ) {
        $arg[ 1 ] = int( ( $size - $wnh ) / 2 + 0.5 );
        @arg[ 5, 6 ] = ( $wnh, $size );
    }

    $image2->copyResized( @arg );
    return $image2->png;
}

=head2 load( $file )

Loads C<$file> and returns a L<GD::Image>.

=cut

sub load {
    my $self = shift;
    my $file = shift;

    my $image;
    if ( $GD::VERSION < 1.30 ) {
        my ( $path, $type ) = $file =~ /(.*)\.([^.]+)/;
        my %new = (
            gif => 'newFromGif',
            png => 'newFromPng',
            jpg => 'newFromJpeg'
        );
        my $new = $new{ lc( $type ) };
        $image = GD::Image->$new( $file );
    }
    else {
        $image = GD::Image->new( $file );
    }

    return $image;
}

=head2 size( $file )

Returns the width and height of C<$file>.

=cut

sub size {
    my $self = shift;
    my $file = shift;

    my $image = $self->load( $file );

    return $image->getBounds();
}

=head1 SEE ALSO

=over 4 

=item * L<GD>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
