package CGI::Application::PhotoGallery::Imager;

use strict;
use warnings;

use Imager;

our $VERSION = '0.16';

=head1 NAME

CGI::Application::PhotoGallery::Imager - Imager-based graphics adaptor

=head1 SYNOPSIS

    use CGI::Application::PhotoGallery::Imager;
    
    my $lib     = CGI::Application::PhotoGallery::Image->new;
    my $pngdata = $lib->resize( $file, 100 );

=head1 METHODS

=head2 new( )

creates a new CGI::Application::PhotoGallery::Imager object.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

=head2 load( $file )

Loads C<$file> and returns an L<Imager> object.

=cut

sub load {
    my $self = shift;
    my $file = shift;

    my $image = Imager->new;
    $image->read( file => $file );
    return $image;
}

=head2 size( $file )

Returns the width and height of C<$file>.

=cut

sub size {
    my $self = shift;
    my $file = shift;

    my $image = $self->load( $file );
    return $image->getwidth, $image->getheight;
}

=head2 resize( $file, $size )

Resizes C<$file> to C<$size>xC<$size> with margins.

=cut

sub resize {
    my $self = shift;
    my $file = shift;
    my $size = shift;

    my $image = $self->load( $file );
    my $type = $image->getwidth > $image->getheight ? 'x' : 'y';

    $image = $image->scale( "${type}pixels" => $size );
    
    my( $w, $h ) = ( $image->getwidth, $image->getheight );
    my $x = $size == $w ? 0 : int( ($size - $w) / 2 );
    my $y = $size == $h ? 0 : int( ($size - $h) / 2 );

    my $newimage = Imager->new( xsize => $size, ysize => $size );
    $newimage->paste( img => $image, left => $x, top => $y );

    my $return;
    $newimage->write( type => 'png', data=> \$return );
    return $return;
}

=head1 SEE ALSO

=over 4 

=item * L<Imager>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
