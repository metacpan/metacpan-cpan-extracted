package Data::FormValidator::Filters::Image;

use strict;

use File::Basename;
use Image::Magick;
use IO::File;
use MIME::Types;

=pod

=head1 NAME

Data::FormValidator::Filters::Image - Filter that allows you to shrink incoming image uploads using Data::FormValidator

=head1 SYNOPSIS

    use Data::FormValidator::Filters::Image qw( image_filter );

    # Build a Data::FormValidator Profile:
    my $my_profile = {
        required => qw( uploaded_image ),
        field_filters => {
            uploaded_image => image_filter(max_width => 800, max_height => 600),
        },
    };

    # Be sure to use a CGI.pm object as the form input
    # when using this filter
    my $q = new CGI;
    my $dfv = Data::FormValidator->check($q,$my_profile);

=head1 DESCRIPTION

Many users when uploading image files never bother to shrink them down to a reasonable size.
Instead of declining the upload because it is too large, this module will shrink the image
down to a reasonable size during the form validation stage.

The filter will try to fail gracefully by leaving the upload as is if the image resize
operation fails.

=cut

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

BEGIN {
    require Exporter;

    $VERSION = '0.40';

    @ISA = qw( Exporter );

    @EXPORT    = ();
    @EXPORT_OK = qw( image_filter );
}

=pod

=head1 FILTERS


=head2 image_filter( max_width => $width, max_height => $height )

This will create a filter that will reduce the size of an image that is
being uploaded so that it is bounded by the width and height provided.
The image will be scaled in a way that will not distort or stretch
the image.

 example:

 - upload an image that is 800 x 600
 - specify a max width of 100 and max height of 100

 The resulting image will be 100 x 75, since that is the
 largest scaled image we can create that is still within
 the bounds we specified.

=cut

sub image_filter {
    my %options    = @_;
    my $max_width  = delete $options{max_width};
    my $max_height = delete $options{max_height};

    return
      sub { return __shrink_image( shift, $max_width, $max_height, %options ) };
}

sub __shrink_image {
    my $fh         = shift;
    my $max_width  = shift;
    my $max_height = shift;
    my @the_rest   = @_;

    # if we weren't given *any* options, there's no point filtering; we're not
    # going to resize the image.
    if ((!defined $max_width) && (!defined $max_height) && !@the_rest) {
        return $fh;
    }

    return $fh unless $fh && ref $fh eq 'Fh';
    my $filename = $fh->asString;
    $filename =~ s/^.*[\/\\]//; # strip off any path information that IE puts in the filename
    binmode $fh;

    my ($result, $image);
    eval {
        # turn the Fh from CGI.pm back into a regular Perl filehandle, then
        # let ImageMagick read the image from _that_ fh.
        my $fh_copy = IO::File->new_from_fd(fileno($fh), 'r');
        $image = Image::Magick->new;
        $result = $image->Read( file => $fh_copy );
    };
    if ($@) {
        #warn "Uploaded file was not an image:  $@";
        seek( $fh, 0, 0 );
        return $fh;
    }
    if ("$result") { # quotes are there as per the Image::Magick examples
        #warn "$result";
        seek( $fh, 0, 0 );
        return $fh;
    }

    my ( $nw, $nh ) = my ( $ow, $oh ) = $image->Get( 'width', 'height' );

    unless ( $ow && $oh ) {
        #warn "Image has no width or height";
        seek( $fh, 0, 0 );
        return $fh;
    }

    if ( $max_width && $nw > $max_width ) {
        $nw = $max_width;
        $nh = $oh * ( $max_width / $ow );
    }
    if ( $max_height && $nh > $max_height ) {
        $nh = $max_height;
        $nw = $ow * ( $max_height / $oh );
    }

    if (($oh <= $max_height) && ($ow <= $max_width)) {
        #warn "Image does not need to be resized";
        seek( $fh, 0, 0 );
        return $fh;
    }

    $result = $image->Resize( width => $nw, height => $nh, @the_rest );
    if ("$result") { # quotes are there as per the Image::Magick examples
        #warn "$result";
        seek( $fh, 0, 0 );
        return $fh;
    }

    #########################
    # Create a file handle object to simulate a CGI.pm upload
    #  Pulled directly from CGI.pm by Lincoln Stein
    my $tmp_filename;
    my $seqno = unpack( "%16C*", join( '', localtime, values %ENV ) );
    $seqno += int rand(100);
    my $newfh;
    for ( my $cnt = 10 ; $cnt > 0 ; $cnt-- ) {
        next unless my $tmpfile = new CGITempFile($seqno);
        $tmp_filename = $tmpfile->as_string;
        last
          if defined( $newfh = Fh->new( $filename, $tmp_filename, 0 ) );
        $seqno += int rand(100);
    }
    die "CGI open of tmpfile: $!\n" unless defined $newfh;
    $CGI::DefaultClass->binmode($newfh)
      if $CGI::needs_binmode
      && defined fileno($newfh);
    #########################

    $image->Write( file => $newfh, filename => $filename );
    if ("$result") { # quotes are there as per the Image::Magick examples
        #warn "$result";
        seek( $fh, 0, 0 );
        return $fh;
    }

    # rewind both filehandles before we return
    seek( $newfh, 0, 0 );
    seek( $fh,    0, 0 );
    return $newfh;
}

1;

__END__

=pod

=head1 SEE ALSO

Data::FormValidator


=head1 AUTHOR

Cees Hek <ceeshek@gmail.com>

=head1 CREDITS

Thanks to SiteSuite (http://www.sitesuite.com.au) for funding the
development of this plugin and for releasing it to the world.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/ORREDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, ORCONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut
