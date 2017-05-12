package AxKit::App::Gallery;

# Copyright (c) 2003 Nik Clayton
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $Id: Gallery.pm,v 1.5 2004/02/26 14:09:52 nik Exp $

use vars qw/$VERSION/;

$VERSION = 0.5;

=head1 NAME

AxKit::App::Gallery - web based image galleries using AxKit

=head1 SYNOPSIS

  AxAddPlugin       AxKit::App::Gallery::Plugin
  AxContentProvider AxKit::App::Gallery::Provider

  # Many AxAddRootProcessor statements to map root elements to
  # stylesheets

  # ...

=head1 DESCRIPTION

AxKit::App::Gallery is a collection of Perl modules, XSLT stylesheets, and
XPathScript stylesheets that implement a web-based image gallery.  The gallery
is generated on the fly, with intelligent caching.

Out of the box, the gallery generates two types of web page.  The first is a
'proofsheet', a collection of image thumbnails.  The second is an
'imagesheet', which contains a single image (which may be viewed at a number
of different resolutions, depending on the gallery's configuration), and
additional information about the image (size, date and time it was taken, and
so on).

This manual page provides an introduction to the application, and how to
configure it once it has been installed.  People interested in extending
AxKit::App::Gallery (::Gallery from here on in) should see the manual pages
for AxKit::App::Gallery::Plugin, AxKit::App::Gallery::Provider, and
AxKit::App::Gallery::stylesheets for further information.

=head1 GALLERY CONFIGURATION

You should collect your images in to one or more directory hierarchies.  The
directories should contain images, and (optionally) sub-directories with more
images.  ::Gallery ignores any non-image files (that is, their MIME type does
not start 'image/').  These images may already be under your webserver's
document root, or you can use an C<Alias> directive to point to them.

You also need to set aside some space for ::Gallery's cache.  This is separate
from AxKit's cache location.  ::Gallery will create directories and files in
this cache, so the cache directory must be writable by the same user under
which you run the webserver.

=head1 APACHE CONFIGURATION

=head2 Create a directory for the stylesheets

The contents of the F<stylesheets/> directory must be copied to somewhere
the web server can read them.

=head2 httpd.conf directives

The root of the directory hierarchy that contains the images must be
configured in Apache.  The F<httpd/> directory contains a commented 
httpd.conf file.  You should add the contents of that file to your Apache
configuration.

=head2 Configure the gallery

Now supply the gallery's configuration options.  These are Perl variables,
set using C<PerlSetVar>.  The available options are:

=over 4

=item ProofSheetColumns

The default proofsheet2html.xsl stylesheet organises the images on the
proofsheet in to a table, C<n> columns wide.  Use this variable to specify
how many columns to use.  The default is C<4>.

    PerlSetVar ProofSheetColumns 6

=item ImagesPerProofsheet

The default proofsheet2html.xsl stylesheet will break the proofsheet up in
to multiple pages if it contains too many images.  Use this variable to
specify how many images to place per page.  The default is C<16>.

    PerlSetVar ImagesPerProofsheet 20

=item GalleryCache

The stylesheets cache the metadata and thumbnails that are generated for
each image.  Use this variable to specify the cache directory.  Additional
subdirectories will be created in this directory as necessary.  There is
no default.

    PerlSetVar GalleryCache /var/tmp/ax-app-gallery

=item GallerySizes

The default stylesheets allow the user to view the images in a number of
different sizes.  This variable is a space-separated string of sizes.
Each size specifies that the longest dimension of the image (either its
width, if it's in landscape orientation, or its height, if it's in
portrait orientation) will be scaled to this size.

The first two numbers in this list have special significance.  The first
number is used to scale the thumbnails that are generated on the
proofsheet.  The second is the default size of the image that will be
shown if the user clicks through on an image on a proofsheet to its
associated <imagesheet> page.

The size may also be C<full>, in which case the end user will be allowed
to download a copy of the original image.

For example, setting this to

    133 640 800 1024 full

(which is also the default) says that:

=over 4

=item *

Thumbnails on the proofsheet will be scaled so that the longest dimension
in each image is 133 pixels.

=item *

The image that is shown when the user clicks through on the <proofsheet>
will be scaled so that the longest dimension in the image is 640 pixels.

=item *

Sizes of 800 and 1024 pixels are also available.

=item *

The end user will be able to download a copy of the original image.

=back

By contrast, a setting of

    133 800 640 1024 full

is identical, except that the default image size after clicking an image
on the proofsheet is 800 pixels, not 640 pixels.  640 pixels is still
available as an option to the end user.

    PerlSetVar GallerySizes '133 800 640 1024 full'

=item GalleryThumbQuality

This specifies the quality of the thumbnails that are produced.  The
default setting, C<normal>, is passed to L<Imager::Transformations> when
scaling the image to create the thumbnails.  This can be set to
C<preview>, which speeds up the thumbnail generation at the expense of the
image quality.  See L<Imager::Transformations> and the C<qtype> parameter
for more information.

    PerlSetVar GalleryThumbQuality preview

=back

=head1 TESTING

That should be all you need to do.  So restart Apache, and point your web
browser at the AxKit::App::Gallery enabled URL.

=head1 SEE ALSO

perl(1). AxKit

=head1 AUTHOR

Nik Clayton, nik@freebsd.org

=head1 BUGS

Undoubtedly.

=cut
