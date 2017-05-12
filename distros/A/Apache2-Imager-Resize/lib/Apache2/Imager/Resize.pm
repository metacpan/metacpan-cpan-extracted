package Apache2::Imager::Resize;
use strict;

use File::Basename ();
use File::Path ();
use Apache2::Const qw(:common);
use Apache2::RequestUtil;
use Apache2::Request;
use APR::Finfo;
use APR::Const qw(:finfo);
use Imager;
use Data::Dumper;

use vars qw($VERSION);
$VERSION = '0.16';

=head1 NAME

Apache2::Imager::Resize - Fixup handler that resizes and crops images on the fly, caching the results, and doesn't require ImageMagick.

=head1 SYNOPSIS

  <Files "*.jpg">
    PerlFixupHandler  Apache2::Imager::Resize
    PerlSetVar ImgResizeCacheDir '/var/cache/AIRCache/'
  </Files>

  # or

  <Location "/liveimages">
    PerlHandler Apache2::Imager::Resize
    PerlSetVar ImgResizeNoCache on
    PerlSetVar ImgResizeWidthParam 'w'
    PerlSetVar ImgResizeHeightParam 'h'
  </Location>

  # and on a web page somewhere:

  <img src="image.jpg?w=300;h=200;proportional=0" width="300" height="200">

=head1 INTRODUCTION

This is a simple fixup class that only does one job: it resizes images before
they're delivered. All you have to do is append either a width and/or a height
parameter to any image file address, and AIR will make sure that an
appropriately shrunken image file is returned. It caches the results of each
operation, so the first request might take a little while but subsequent
similar requests should be very quick.

This module is based on the code from L<Apache::Imager::Resize>, which does the
same job for Apache 1.x. Some new parameters have been adden, but preexisting
parameters are backwards-compatible.

=head1 PARAMETERS

Apache2::Imager::Resize understands four query string parameters:

=head2 w

width in pixels. You can specify another name with an ImgResizeWidthParam directive.

=head2 h

height in pixels. You can specify another name with an ImgResizeHeightParam directive.

=head2 reshape

If this is 'crop', we will crop without resizing. The default behaviour is
to scale first and then crop to fit the other dimension (see below). If only
one dimension is specified, this parameter has no effect. There will be more
options here in later versions.

=head2 cropto

This can be left, right, top or bottom, and it dictates the part of the picture
that is kept when we crop the image. If only one dimension is specified, this
parameter has no effect. Future versions will allow combinations of these values.

=head2 quality

This should be an integer between 0 and 100. It only affects jpeg images. The default is 60.

=head2 enlarge

By default images won't images get scaled up. If you wan't to do this, set enlarge to 1.

=head2 cropAR

Overrides the default behaviour of configuration parameter "ImgResizeCropToAspectRatio".

=head2 scaletype

Scale type 'min', 'max', 'nonprop'. See L<Imager::Transformations/scale>.

=head2 qtype

Quality of scaling 'normal', 'preview', 'mixing'. See L<Imager::Transformations/scale>.

=head1 CONFIGURATION

In many cases, this will suffice:

  <Location "/images">
    PerlFixupHandler  Apache::Imager::Resize
  </Location>

But you can also include one or more of these directives to modify the behaviour of the handler:

=head2 ImgResizeCacheDir

Sets the path to a directory that will be used to hold the resized versions of image
files. If you don't include this directive, resized images will be stored next to their
originals. The supplied value should be relative to your document root, eg:

  <Location "/images">
    PerlFixupHandler  Apache::Imager::Resize
    PerlSetVar ImgResizeCacheDir '/var/cache/AIRCache/'
  </Location>

You can put the cache inside a directory that is handled by AIR without ill effects,
though of course it will get a bit odd if you start serving images directly from the cache.

=head2 ImgResizeNoCache

If true, this will mean that images are resized for each request and no attempt
is made to keep a copy for future use.

=head2 ImgResizeWidthParam

Sets the name of the parameter that will be used to specify the width (in pixels)
of the returned image. Default is 'w'.

=head2 ImgResizeHeightParam

Sets the name of the parameter that will be used to specify the height (in pixels)
of the returned image. Default is 'h'.

=head2 ImgResizeCropToAspectRatio

If true, the image will be cropped if the specified width and height would lead to
a new aspect ratio. Default is '1'. The parameter 'cropAR' can be used to override
this behaviour.

=head2 ImgResizeQtype

Sets the default value for L</qtype>.

=head1 IMAGE FORMATS

We can work with any image format that L<Imager> can read, which includes all the
usual web files and most other bitmaps.

=head1 SHRINKING RULES

If only one dimension is specified, we will scale the image to that size,keeping
the aspect ratio.

If both dimensions are specified and the combination preserves the aspect ratio
of the image, we scale the image to that size.

If there is no 'reshape' parameter, the specified dimensions result in a change
of shape and the parameter "proportional" is set to 0, the aspect ratio of the
image will be changed.

If there is no 'reshape' parameter, and the specified dimensions result in a
change of shape, we will first scale the image to the correct size in the dimension
that is changing less, then crop in the other dimension to achieve the right shape
and size without distorting the image. You can supply a 'cropto' parameter to specify
which part of the image is kept in the cropping step. You can set "ImgResizeCropToAspectRatio"
to 0 or the parameter "cropAR" to avoid the cropping of the image.

If the reshape parameter is 'crop', we will crop in both dimensions without scaling
the image at all. You can supply a 'cropto' parameter to specify which part of the
image is kept. This is likely to yield better quality than scaling, when the original
size is close to the target size, but will have less useful results where they're
very different.

=head1 CACHING AND EFFICIENCY

Unless you've switched the cache off, the handler keeps a copy of every resized
file. When a request comes in, we look first for a cached file, and check that it's
no older than the original image file.

By default we keep the cache files next to the originals, which can get messy. You
can also specify a cache directory, in which the directory structure of your site
will be partly recreated as resized images are stored in subdirectories corresponding
to the position of their originals in the main filing system. This makes it much
easier to prune or discard the cache.

Note that at the moment it is assumed that your image cache will be within your
document root. There's no reason why it should have to be, so at some point soon
it will be possible to specify a whole page.

Either way, this request:

  <img src="/images/morecambe.jpg?w=120&h=150&cropto=left">

will produce (or use) a cache file named:

  [cachedir]/images/morecambe_120_150_left.jpg

If either dimension is not specified, as is common, the filename will have an x
in that position. The cropto parameter is also usually omitted, so this:

  <img src="/images/morecambe.jpg?w=120">

corresponds to this:

  [cachedir]/images/morecambe_120_x.jpg

If neither width nor height is specified we bail out immediately, so the original
image will be returned.

There is currently no mechanism for cache cleanup, but we do touch the access
date of each file each time it's used (leaving the modification date alone so that
it can be to compare with the original file). You could fairly easily set up a cron
job to go through your cache directory deleting all the image files that have not
been touched for a week or so.

=cut

sub handler {
    my $r = Apache2::Request->new(shift);

    my $filename = $r->filename;

    my $nocache = $r->dir_config('ImgResizeNoCache');
    my $cachedir = $r->dir_config('ImgResizeCacheDir');
    $cachedir .= '/' if ( $cachedir !~ /\/$/);
    my $widthparm = $r->dir_config('ImgResizeWidthParam') || 'w';
    my $heightparm = $r->dir_config('ImgResizeHeightParam') || 'h';
    my $default_quality = $r->dir_config('ImgResizeDefaultQuality') || '60';
    my $default_qtype = $r->dir_config('ImgResizeQtype') || 'normal';
    my $crop_aspect_ratio = $r->dir_config('ImgResizeCropToAspectRatio');
    $crop_aspect_ratio = 1 unless defined $crop_aspect_ratio;

    # read basic input
    my %img_args;
    $img_args{w} = int( $r->param($widthparm) );
    $img_args{h} = int( $r->param($heightparm) );
    return OK unless $img_args{w} || $img_args{h};

    $img_args{cropto} = $r->param('cropto');
    $img_args{reshape} = $r->param('reshape');
    $img_args{enlarge} = $r->param('enlarge') || 0 ;
    $img_args{crop_aspect_ratio} = defined $r->param('cropAR') ? $r->param('cropAR') : $crop_aspect_ratio;
    $img_args{proportional} = $r->param('proportional');
    $img_args{proportional} = 1 if not defined $img_args{proportional} or $img_args{proportional} eq '';
    my $quality = $r->param('quality') || $default_quality;
    $img_args{scale_type} = $r->param('scaletype');
    $img_args{qtype} = $r->param('qtype') || $default_qtype;

    my $shrunk;
    my ($name, $path, $suffix) = File::Basename::fileparse( $filename, '\.\w{2,5}' );

    unless ($nocache) {
        my $docroot = $r->document_root;

        # interpolate the name of the cache directory if it has been supplied
        $path =~ s/^$docroot/$cachedir/ if $cachedir;
        $path =~ s/\/\//\//;
        $shrunk = $path . $name . '_' . ( $img_args{w} || 'x' ) . '_' . ( $img_args{h} || 'x' );
        $shrunk .= "_q$quality";

        if ($img_args{reshape} eq 'crop') {
            $shrunk .= '_crop';
        }

        if ($img_args{cropto} && $img_args{cropto} =~ /^(left|right|top|bottom)$/i) {
            $shrunk .= "_".$img_args{cropto};
        }

        if ($img_args{enlarge}) {
            $shrunk .= "_enlarge";
        }

        if ($img_args{proportional}) {
            $shrunk .= "_proportional";
        }

        if ($img_args{crop_aspect_ratio}) {
            $shrunk .= "_cropAR";
        }

        if ($img_args{scale_type}) {
            $shrunk .= "_scaletype".$img_args{scale_type};
        }

        if ($img_args{qtype}) {
            $shrunk .= "_qtype".$img_args{qtype};
        }

        $shrunk .= $suffix;

        if (file_ok( $shrunk, $filename )) {
            $r->filename($shrunk);
            $r->finfo(APR::Finfo::stat($shrunk, APR::Const::FINFO_NORM, $r->pool));
            my $mtime = (stat( $shrunk ))[9];
            utime time, $mtime, $shrunk;
            return OK;
        }

        # if we're using a separate cache directory, the necessary subdirectory might not exist yet

        if ($cachedir) {
            eval {  File::Path::mkpath($path) };
            return fail( "mkpath failed for '$path': $@" ) if $@;
        }
    }

    # no cache hit, so we create an Imager object and go through the options
    my $im = Imager->new;
    $im->open( file => $filename ) or return fail("Cannot read $filename: " . $im->errstr);
    $im = resize($im, \%img_args);

    # if the cache is disabled, we write the results directly back to the request.
    # You shouldn't do this during fixup - though it works - so if running without a cache we ought to a perlhandler

    if ($nocache) {
        my $type = $suffix;
        $type =~ s/^\.//;
        $type = 'jpeg' if $type eq 'jpg';

        my $imagedata;
        $im->write(
            type => $type,
            jpegquality => $quality,
            data => \$imagedata,
        ) or return fail( "Failed to return image data: " . $im->errstr );

        $r->headers_out->{'Content-Length'} = length($imagedata);
        $r->content_type("image/$type");
        $r->print($imagedata);
        return OK;

    # otherwise we write out the cache file and tell the request to use that filename

    } else {

        $im->write(
            file => $shrunk,
            jpegquality => $quality,
        ) or return fail("Cannot write $shrunk: " . $im->errstr);

        $r->filename($shrunk);
        $r->finfo(APR::Finfo::stat($shrunk, APR::Const::FINFO_NORM, $r->pool));
        return OK;
    }
}

sub resize {
    my $im = shift;
    my $args = shift;

    my $imgwidth = $im->getwidth;
    my $imgheight = $im->getheight;
    my (%scale, %crop);

    ##############
    # scale the image
    if ($args->{w} && $args->{h}) {
        if ($args->{reshape} eq 'crop') {
            %scale = ();
        }
        else {
            # Imager automatically resizes to make the larger image specified by the two dimensions
            $scale{xpixels} = $args->{w};
            $scale{ypixels} = $args->{h};
        }

    } elsif ($args->{w}) {
        $scale{xpixels} = $args->{w};

    } else {
        $scale{ypixels} = $args->{h};
    }

    if ($args->{qtype}) {
        $scale{qtype} = $args->{qtype};
    }

    if ($args->{scale_type}) {
        $scale{type} = $args->{scale_type};
    }

    # enlarge images only if the enlarge argument is set
    if (
        not $args->{enlarge}
        and (
            ( $scale{xpixels} and ($scale{xpixels} > $imgwidth) )
            or ( $scale{ypixels} and ($scale{ypixels} > $imgheight) )
        )
        and (
            ($args->{scale_type} ne 'min')
            or (
                ( $scale{xpixels} and ($scale{xpixels} > $imgwidth) )
                and ( $scale{ypixels} and ($scale{ypixels} > $imgheight) )
            )
        )
    ) {
        %scale = ();
    }

    if ( not $args->{proportional} and $scale{xpixels} and $scale{ypixels} ) {
        $im = $im->scaleX(pixels=>$scale{xpixels})->scaleY(pixels=>$scale{ypixels});
    }
    elsif( %scale ) {
        $im = $im->scale( %scale );
    }

    ###############
    # crop the image
    if ($args->{w} && $args->{h} && ($args->{crop_aspect_ratio} || $args->{reshape} || $args->{cropto}) ) {

        # $dw and $dh are the multipliers by which each dimension is changing

        my $dw = $imgwidth / $args->{w} if $args->{w};
        my $dh = $imgheight / $args->{h} if $args->{h};

        # cropto should really be a list parameter so that we can choose top left

        if ($args->{reshape} eq 'crop') {
            if ($args->{cropto} eq 'left') {
                $crop{left} = 0;
                $crop{width} = $args->{w};
                $crop{height} = $args->{h};

            } elsif ($args->{cropto} eq 'right') {
                $crop{right} = $imgwidth;
                $crop{width} = $args->{w};
                $crop{height} = $args->{h};

            } elsif ($args->{cropto} eq 'top') {
                $crop{top} = 0;
                $crop{width} = $args->{w};
                $crop{height} = $args->{h};

            } elsif ($args->{cropto} eq 'bottom') {
                $crop{bottom} = $imgheight;
                $crop{width} = $args->{w};
                $crop{height} = $args->{h};

            } else {
                $crop{width} = $args->{w};
                $crop{height} = $args->{h};
            }

        } elsif ($dw > $dh) {

            if ($args->{cropto} eq 'left') {
                $crop{left} = 0;
                $crop{width} = $args->{w};
            } elsif ($args->{cropto} eq 'right') {
                $crop{right} = $im->getwidth;
                $crop{width} = $args->{w};
            } else {
                $crop{width} = $args->{w};;
            }

        } elsif ($dh > $dw) {

            if ($args->{cropto} eq 'top') {
                $crop{top} = 0;
                $crop{height} = $args->{h};
            } elsif ($args->{cropto} eq 'bottom') {
                $crop{bottom} = $im->getheight;
                $crop{height} = $args->{h};
            } else {
                $crop{height} = $args->{h};
            }
        }

        # if dw == dh, no cropping is required.
        # then we scale the image, if any resizing remains to be done

        $im = $im->crop( %crop ) if %crop;
    }

    return $im;
}

# file_ok tests whether the given file exists and is useable
# you can also supply the original file path as a second parameter: in that case
# we will test whether the original is newer than our file, and reject the file if it is

sub file_ok {
    my ($filename, $original) = @_;
    return unless -e $filename;
    return unless -r _;
    return unless -s _;
    return if $original && -M _ > -M $original;     # nb. this is age, not time
    return 1;
}

# a general purpose and rather feeble error handler. This should log through the request, at least.

sub fail {
    my $message = shift;
    my ($package, $filename, $line) = caller;
    warn "$message at $package line $line\n";
    return SERVER_ERROR;
}

=head1 BUGS

No doubt. Reports in rt.cpan.org would be much appreciated.

=head1 TODO

=over

=item * Accept more than one cropto parameter, eg top and left.

=item * tests

=back

=head1 SEE ALSO

L<Imager> L<Apache::ImageMagick> L<Apache::GD::Thumbnail> L<Apache::Imager::Resize>

=head1 AUTHOR

Alexander Keusch, C<< <kalex at cpan.org> >>

=head1 CONTRIBUTORS

William Ross, C<< <wross at cpan.org> >>
Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
