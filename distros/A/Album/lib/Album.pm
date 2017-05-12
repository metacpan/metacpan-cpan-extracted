package Album;

( $VERSION ) = '$Revision: 1.9 $ ' =~ /\$Revision:\s+([^\s]+)/;

# NOTE: This is a documentation-only module.

use strict;

=head1 NAME

Album - Create and maintain browser based photo albums

=head1 SYNOPSIS

A photo album consists of a number of (large) pictures, small thumbnail
images, and index pages. Optionally, medium sized images can be
generated as well. Also, it is possible to embed other albums.

The album will be organised as follows:

  index.html       first or only index page
  indexN.html      subsequent index pages (N = 1, 2, ...)
  icons/           directory with navigation icons
  css/		   directory with stylesheets
  large/           original (large) images, with HTML pages
  medium/          optional medium sized images, with HTML pages
  thumbnail/       thumbnail images

Each image can be labeled with a description, a tag (applies to a
group of images, e.g. a date), the image name, and some
characteristics (size and dimensions).

Images can be handled 'in situ', or imported from e.g. a CD-ROM or
digital camera. Optionally, EXIF information from digital camera files
can be taken into account.

The photo albums are the digital equivalents of paper albums, but
easier to create and maintain. Although you can publish a photo album
on the Web, this tool is not specifically targeted at creating Web
shows.

=head1 DESCRIPTION

For a description how to use the program, see L<Album::Tutorial>.

=head1 DEPENDENCIES

B<Album> requires the following Perl modules, all available on CPAN:

=over 4

=item *

File::Spec (Standard part of perl 5.8)

=item *

Image::Info

=item *

Image::Magick (PerlMagick). Of course, this requires an ImageMagick
install as well.

=back

The following tools / packages will be used if available:

=over 4

=item *

jpegtrans, a tool for lossless JPEG rotation

=item *

mplayer, to manipulate MPEG movies and VOICE images

=item *

mencoder, to manipulate MPEG movies

=back

=head1 BUGS AND PROBLEMS

Some versions of Perl may exhibit Data::Dumper problems with non-ASCII
data. Perl 5.6.x and 5.8.3 and later should be fine.

=head1 AUTHOR AND CREDITS

Johan Vromans (jvromans@squirrel.nl) wrote this module.

Web site: L<http://www.squirrel.nl/people/jvromans/Album/index.html>.

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2004 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut

1;

# $Id: Album.pm,v 1.9 2006/10/20 14:47:56 jv Exp $
