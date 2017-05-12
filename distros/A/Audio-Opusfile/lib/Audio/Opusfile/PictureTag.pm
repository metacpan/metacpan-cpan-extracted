package Audio::Opusfile::PictureTag;
# Don't load this module directly, load Audio::Opusfile instead

use 5.014000;
use strict;
use warnings;
use subs qw/parse/;

our $VERSION = '0.005001';

sub new { parse $_[1] }

1;
__END__

=encoding utf-8

=head1 NAME

Audio::Opusfile::PictureTag - A parsed METADATA_BLOCK_PICTURE tag

=head1 SYNOPSIS

  use Audio::Opusfile;
  my $of = Audio::Opusfile->new_from_file('file.opus');
  my @pic_tags = $of->tags->query_all('METADATA_BLOCK_PICTURE');
  my @pictures = map { Audio::Opusfile::PictureTag->parse($_) } @pic_tags;
  my $pic = $pictures[0];
  say $pic->type; # Prints "3", which means Cover (front)
  say $pic->mime_type; # Prints "image/png"
  say $pic->description;
  say $pic->width;
  say $pic->height;
  say $pic->depth;
  say $pic->colors;
  say $pic->data_length; # The image size
  my $data = $pic->data; # The contents of the image
  say $pic->format; # One of the OP_PIC_* constants

=head1 DESCRIPTION

This module represents a METADATA_BLOCK_PICTURE tag. It has the
following methods (descriptions taken from the libopusfile
documentation):

=over

=item Audio::Opusfile::PictureTag->B<new>(I<$tag>)

Takes the contents of a METADATA_BLOCK_PICTURE tag (optionally
prefixed by the string C<METADATA_BLOCK_PICTURE=>) and returns a new
Audio::Opusfile::PictureTag object.

=item $pic->B<type>

The picture type according to the ID3v2 APIC frame

   0.  Other
   1.  32x32 pixels 'file icon' (PNG only)
   2.  Other file icon
   3.  Cover (front)
   4.  Cover (back)
   5.  Leaflet page
   6.  Media (e.g. label side of CD)
   7.  Lead artist/lead performer/soloist
   8.  Artist/performer
   9.  Conductor
   10. Band/Orchestra
   11. Composer
   12. Lyricist/text writer
   13. Recording Location
   14. During recording
   15. During performance
   16. Movie/video screen capture
   17. A bright colored fish
   18. Illustration
   19. Band/artist logotype
   20. Publisher/Studio logotype

Others are reserved and should not be used. There may only be one each
of picture type 1 and 2 in a file.

=item $pic->B<mime_type>

The MIME type of the picture, in printable ASCII characters 0x20-0x7E.

The MIME type may also be "-->" to signify that the data part is a URL
pointing to the picture instead of the picture data itself. In this
case, a terminating NUL is appended to the URL string in data, but
data_length is set to the length of the string excluding that
terminating NUL.

=item $pic->B<description>

The description of the picture, in UTF-8.

=item $pic->B<width>

The width of the picture in pixels.

=item $pic->B<height>

The height of the picture in pixels.

=item $pic->B<depth>

The color depth of the picture in bits-per-pixel (not
bits-per-channel).

=item $pic->B<colors>

For indexed-color pictures (e.g., GIF), the number of colors used, or
0 for non-indexed pictures.

=item $pic->B<data_length>

The length of the picture data in bytes. Equivalent to C<< length ($pic->data) >>.

=item $pic->B<data>

The binary picture data.

=item $pic->B<format>

The format of the picture data, if known. One of:
OP_PIC_FORMAT_UNKNOWN, OP_PIC_FORMAT_URL, OP_PIC_FORMAT_JPEG,
OP_PIC_FORMAT_PNG, or OP_PIC_FORMAT_GIF.

=back

=head1 SEE ALSO

L<Audio::Opusfile>,
L<http://opus-codec.org/>,
L<http://opus-codec.org/docs/opusfile_api-0.7/index.html>,
L<https://www.opus-codec.org/docs/opusfile_api-0.7/structOpusPictureTag.html>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
