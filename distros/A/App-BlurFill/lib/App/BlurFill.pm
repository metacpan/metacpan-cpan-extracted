=head1 NAME

App::BlurFill - A simple command line tool to create a blurred background image

=head1 SYNOPSIS

  use App::BlurFill;

  my $blur_fill = App::BlurFill->new(
    file    => 'path/to/image.jpg',
    width   => 650,
    height  => 350,
  );

  my $output = $blur_fill->process;
  print "Blurred image saved to: $output\n";

=head1 DESCRIPTION

App::BlurFill is a simple command line tool to create a blurred background image
from a given image. It scales the image to a specified width and height, applies
a Gaussian blur, and saves the result as a new image.

=head1 METHODS

=head2 new

  my $blur_fill = App::BlurFill->new(
    file    => 'path/to/image.jpg',
    width   => 650,
    height  => 350,
  );

Creates a new App::BlurFill object. The following parameters are accepted:

=over 4

=item * file

The path to the input image file. This parameter is required.
=item * width

The width of the output image. Default is 650 pixels.

=item * height

The height of the output image. Default is 350 pixels.

=item * output

The path to the output image file. If not specified, a filename will be generated
based on the input file name and saved in the same directory. The output file
will have a "_blur" suffix added to the original filename.

=back

=head2 process

  my $output = $blur_fill->process;
  print "Blurred image saved to: $output\n";

Processes the input image, applies a Gaussian blur, and saves the result as a
new image. Returns the path to the output image file.

=cut

package App::BlurFill; # For MetaCPAN

use v5.40;
use experimental 'class';

class App::BlurFill {
  our $VERSION = '0.0.5';

  use Imager;
  use File::Basename 'fileparse';
  use File::Temp 'tempdir';

  field $file    :param;
  field $width   :param = 650;
  field $height  :param = 350;

  field $output  :param = do {
    my ($name, $path, $ext) = fileparse($file, qr/\.[^.]*$/);
    $path =~ s[/$][];

    my $dir = caller eq 'App::BlurFill::CLI' ? $path : tempdir(CLEANUP => 1);

    my $filename = "${name}_blur$ext";

    "$dir/$filename";
  };

  field $imager  :param = Imager->new(file => $file);

  method process {
    my $background = $imager->copy;

    $background = $background->scale(xpixels => $width);
    my $bg_height = $background->getheight;
    $background = $background->crop(
      top    => ($bg_height / 2) - ($height / 2),
      bottom => ($bg_height / 2) + ($height / 2),
    );
    $background->filter(type => 'gaussian', stddev => 15);

    my $img = $imager->scale(ypixels => $height);
    my $img_width = $img->getwidth;

    $background->compose(src => $img, left => ($width / 2) - ($img_width / 2));
    $background->write(file => $output, type => 'png') or die $background->errstr;

    return $output;
  }
}

=pod

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025, Magnum Solutions Ltd. All rights reserved.

This is free software; you can redistribute it and/or modify it under the

=cut
