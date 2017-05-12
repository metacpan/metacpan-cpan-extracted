package Apache::Image;
use warnings;
use strict;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK NOT_FOUND HTTP_MOVED_TEMPORARILY);
use Apache2::TrapSubRequest;

# XXX - Bug with getting uri/path_info
# 	If /z/image exists it works
# 	If /z/image does not, it is all broken
# 	If /z/image/thubnail exists it drops the first part of path info !
# 	all bad

# XXX We should use Image::Thumbnail !!!
use Image::Magick;

use Carp;
use version; our $VERSION = qv('0.0.4');

# TODO Can this be made to be Apaceh 1.3 (mod_perl 1) ? If not document the reason

sub handler {
	my $r = shift;

	# URI (original) & Configuration
	my $uri=$r->path_info;

	# Get the size from config
	my $MaxSize=$r->dir_config("ImageMaxSize") || 50;

	# Force this size? Or only resize if larger?
	my $Force=$r->dir_config("ImageForce") || 0;

        # Get our image from Apache
        my $image;
        my $subr = $r->lookup_uri($uri);
	# XXX Do other things like POST data etc.
	$subr->args($r->args);
        $subr->run_trapped(\$image);
	
	# XXX Check not found or other error
	# XXX Check the Pragma and Expiry times for caching and setting local expiry times

        # Check mime type is image (else return based on mime type)
        if ($subr->content_type !~ m|^image/([^\s]+)|) {
                # print STDERR "Not a valid type for $rest " .  $subr->content_type . "\n";
		# XXX Get this from configuration
                $r->internal_redirect("/z/resource/thumbnail/unknown.jpg");
		# TODO Support mime type mapping to files (can we use Apache for this?)
		# TODO Future - Support creation of Thumbnails from other sources
                return Apache2::Const::OK;
        }

	# XXX Caching - Write entries to a directory and use internal redirect
	# to get them - only problem may be that a tif wants to be a jpg
	# thumbnail
	# $r->internal_redirect("/unknown.jpg");

        # Process the image into a thumbnail and output
        my $im = Image::Magick->new;
        $im->BlobToImage($image);

	# Resize if Force or Too big !
	if ($Force || ($im->Get('width') > $MaxSize) || ($im->Get('height') > $MaxSize)) {
		$im->Scale(geometry => $MaxSize . 'x' . $MaxSize);
	}

	# XXX Is it always ?
        $r->content_type('image/jpg');
        $r->rflush();
        print $im->ImageToBlob();
	
	# XXX Save to cache (files to redirect to) (internal Apache caching)
	
        return Apache2::Const::OK;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Apache::Image - Generate a new image size, e.g. Thumbnail on the fly of any image, even dynamically generated (EXPERIMENTAL RELEASE)

=head1 VERSION

This document describes Apache::Image version 0.0.1

=head1 SYNOPSIS

	# Where are my images
	Alias /myimages /tmp/images

	# Example URL for Thumbnail version of /myimages/TheBeach/Friend.jpg
	# http://localhost/z/image/thumbnail/myimages/TheBeach/Friend.jpg

	# Thumbnail versions
	<Location /z/image/thumbnail>
		SetHandler perl-handler
		PerlHandler Apache::Image
		PerlSetVar ImageMaxSize 80
	</Location>

	# Medium views
	<Location /z/image/medium>
		SetHandler perl-handler
		PerlHandler Apache::Image
		PerlSetVar ImageMaxSize 400
	</Location>

=head1 DESCRIPTION

Automatically generate thumbnail images on the fly from any Apache source. This
includes but is not limited to: local files; Subversion; Generated / Dynamic
images from CGIâ PHP, mod_perl and more.

Features: (XXX fix formating)

	* Generate thumbnails of any size
	* Fast caching (using internal redirects to local file handles)
	* Content of original can come from any source
	
=head1 INTERFACE 

=head1 DIAGNOSTICS

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Apache::Image requires no configuration files or environment variables.


=head1 DEPENDENCIES

Currently Image::Magick but soon to be Image::Thumbnail to allow independence
of backend.

Future to include another Image Thumbnail module for non images (movie frames,
word doc, pdf and others).

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-apache-thumbnail@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Scott Penrose  C<< <scottp@dd.com.au> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Scott Penrose C<< <scottp@dd.com.au> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
