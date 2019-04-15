package App::WRT::Image;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(image_size);

use Image::Size;

=over

=item image_size($path)

Returns (width, height) of a variety of image files.  Called by icon_markup and
line_parse.

=cut

sub image_size {
  return imgsize($_[0]);
}

=back

1;
