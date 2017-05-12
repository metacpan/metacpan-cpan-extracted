package Catalyst::View::Thumbnail;

use warnings;
use strict;
use parent 'Catalyst::View';
use Image::Info qw/image_info/;
use Imager;
use List::Util qw/min max/;

=head1 NAME

Catalyst::View::Thumbnail - Catalyst view to resize images for thumbnails

=cut

our $VERSION = '0.03';

sub process {
  my ($self, $c) = @_;

  my $image = $self->render_image($c);
  
  # render_image() will return an Imager object on success,
  # or an error message on failure.
  
  if (UNIVERSAL::isa($image, 'Imager')) {
    my $mime_type = $c->stash->{image_type} || image_info(\$c->stash->{image})->{file_media_type};
    (my $file_type = $mime_type) =~ s!^image/!!;

    my $thumbnail;
    $image->write(
      data => \$thumbnail,
      type => $file_type,
    );
  
    $c->response->content_type($mime_type);
    $c->response->body($thumbnail);    
  } else {
    my $error = qq/Couldn't render image: $image/;
    $c->log->error($error);
    $c->error($error);
    return 0;    
  }
}


sub render_image {
  my ($self, $c) = @_;
  
  return "Image data missing from stash" unless $c->stash->{image};
  
  my $image = Imager->new();
  $image->read(data => $c->stash->{image}) or return $image->errstr;
  
  if ($c->stash->{zoom}) {
    $image = $image->crop(
      width  => $image->getwidth * ($c->stash->{zoom} / 100),
      height => $image->getheight * ($c->stash->{zoom} / 100),
    ) or return $image->errstr;
  }
  
  if ($c->stash->{x} or $c->stash->{y}) {
    $c->log->debug('Creating thumbnail image');
    my $source_aspect = $image->getwidth / $image->getheight;
    $c->log->debug('Source width: ' . $image->getwidth . ' height: ' . $image->getheight . ' aspect ratio: ' . $source_aspect);
    $c->stash->{x}  ||= $c->stash->{y} * $source_aspect;
    $c->stash->{y}  ||= $c->stash->{x} / $source_aspect;

    $c->log->debug('Target width: ' . $c->stash->{x} . ' height: ' . $c->stash->{y});
    
    unless ($c->stash->{scaling} eq 'fit') {
      my $thumbnail_aspect = $c->stash->{x} / $c->stash->{y};
      $c->log->debug('Thumbnail aspect ratio: ' . $thumbnail_aspect);
      
      if ($source_aspect > $thumbnail_aspect) {
        $c->log->debug('Cropping image to fit aspect ratio of thumbnail');
        $c->log->debug('Source aspect > thumbnail aspect');
        $c->log->debug('Cropping to width: '.$image->getheight * $thumbnail_aspect.' x height: '.$image->getheight);
        $image = $image->crop(
          width  => $image->getheight * $thumbnail_aspect,
          height => $image->getheight,
        ) or return $image->errstr;
      }
      
      if ($source_aspect < $thumbnail_aspect) {
        $c->log->debug('Cropping image to fit aspect ratio of thumbnail');
        $c->log->debug('Source aspect < thumbnail aspect');
        $c->log->debug('Cropping to width: '.$image->getwidth.' x height: '.$image->getwidth / $thumbnail_aspect);
        $image = $image->crop(
          width  => $image->getwidth,
          height => $image->getwidth / $thumbnail_aspect,
        ) or return $image->errstr;
      }
    }
    
    $c->log->debug('Scaling image to thumbnail');
    $image = $image->scale(
      xpixels => $c->stash->{x},
      ypixels => $c->stash->{y},
      type    => 'min',
      qtype   => 'mixing',
    ) or return $image->errstr;
  }

  return $image;
}

=head1 SYNOPSIS

Create a thumbnail view:

 script/myapp_create view Thumbnail Thumbnail

Then in your controller:

 sub thumbnail :Local :Args(1) {
    my ($self, $c, $image_id) = @_;
    
    my $image_obj = $c->model('MyApp::Images')->find({id=>$image_id})
      or $c->detach('/default');
    
    $c->stash->{x}     = 100;    # Create a 100px square thumbnail
    $c->stash->{y}     = 100;
    $c->stash->{image} = $image_obj->data;
    
    $c->forward('View::Thumbnail');
 }

=head1 DESCRIPTION

Catalyst::View::Thumbnail resizes images to produce thumbnails, with options to set the desired x or y
dimensions (or both), and specify a zoom level and scaling type.

=head2 Options

The view is controlled by setting the following values in the stash:

=over

=item image

Contains the raw data for the full-size source image.

This is a mandatory option.

=item x

The width (in pixels) of the thumbnail.

This is optional, but at least one of the C<x> or C<y> parameters must be set.

=item y

The height (in pixels) of the thumbnail.

This is optional, but at least one of the C<x> or C<y> parameters must be set.

=item zoom

Zoom level, expressed as a number between 1 and 100.

If the C<zoom> option is given, the thumbnail will be 'zoomed-in' by the
appropriate amount, e.g. a zoom level of 80 will create a thumbnail using the
middle 80% of the source image.

This parameter is optional, if omitted then a zoom level of 100 will be used,
i.e. create thumbnails using 100% of the source image.

=item scaling

Scaling type, can be either 'fit' or 'fill'.

If both the C<x> and C<y> parameters are set, the aspect ratio (x/y) of the
thumbnail image may not match the aspect ratio of the source image.

To prevent the thumbnail from looking 'stretched', there is a choice of two
scaling options:

=over

=item fit

Fits the thumbnail within the specified C<x> and C<y> dimensions, preserving
all of the source image.

Note that by using this scaling method, the generated thumbnails may be smaller
than the the specified C<x> and C<y> dimensions.

=item fill

Fills the thumbnail to the exact C<x> and C<y> dimensions as specified, cropping
the source image as necessary.

=back

This parameter is optional, and will default to 'fill' if omitted.

=item image_type

Mime type for the output image.  This is normally the same as the input image.
If you set this the Imager library will produce an image of that format.  This
is useful when you want to convert something like a tiff to a jpeg.  Note
that the conversions can be strange so this may not be a good idea for all images.
See the C<Imager> documentation for more details.

=back

=head2 Image formats

The generated thumbnails will always be produced in the same format (PNG, JPG, etc)
as the source image.

Catalyst::View::Thumbnail uses the L<Imager> module to crop and resize images,
so will accept any image format supported by I<Imager>.

Please see the L<Imager> documentation for more details and installation notes.

=head1 SEE ALSO

Catalyst::View::Thumbnail tutorial (with examples): L<http://perl.jonallen.info/writing/articles/creating-thumbnails-with-catalyst>

=head1 AUTHOR

Jon Allen (JJ), C<< <jj@jonallen.info> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-thumbnail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Thumbnail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

Commercial support, customisation, and training for this module is available
from Penny's Arcade Limited - contact L<info@pennysarcade.co.uk> for details.

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Thumbnail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-Thumbnail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-Thumbnail>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-Thumbnail/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Jon Allen (JJ).

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This module is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. 

=cut

1; # End of Catalyst::View::Thumbnail
