package Apache::Imager::Resize;
use strict;

use File::Basename ();
use File::Path ();
use Apache::Constants (':common');
use Imager;
use Data::Dumper;

use Apache::ModuleConfig ();
use DynaLoader ();

use vars qw($VERSION);
$VERSION = '0.11';

if($ENV{MOD_PERL}) {
	no strict;
	push @ISA, 'DynaLoader';
	__PACKAGE__->bootstrap($VERSION);
}

=head1 NAME

Apache::Imager::Resize - Fixup handler that resizes and crops images on the fly, caching the results, and doesn't require ImageMagick.

=head1 SYNOPSIS

  <Files "*.jpg">
	PerlFixupHandler  Apache::Imager::Resize
	ImgResizeCacheDir '/imgcache'
  </Files>
  
  # or
  
  <Location "/liveimages">
	PerlHandler Apache::Imager::Resize
	ImgResizeNoCache on
 	ImgResizeWidthParam 'w'
	ImgResizeHeightParam 'h'
  </Location>

  # and on a web page somewhere:

  <img src="image.jpg?w=300&h=200" width="300" height="200">

=head1 INTRODUCTION

This is a simple fixup class that only does one job: it resizes images before they're delivered. All you have to do is append either a width and/or a height parameter to any image file address, and AIR will make sure that an appropriately shrunken image file is returned. It caches the results of each operation, so the first request might take a little while but subsequent similar requests should be very quick.

There are other modules that you could do this with: see the links at the bottom of this pod. If your requirements might include more complicated transformations, or you're running mod_perl behind a thin proxy, you're probably better off with L<Apache::ImageMagick>. There are also several solutions for thumbnailing, but if your only requirement is to be able to show images at an arbitrary size in a simple, clean way, this module might be for you.

The handler uses Imager to do the work. I intend to produce a proper general-purpose Apache::Imager package, if nobody else does, so this will end up being a special case with a simplified interface, and will probably live alongside an Apache::Imager::Translate and other useful shortcut modules.

=head1 PARAMETERS

Apache::Imager::Resize understands four query string parameters:

=head2 w

width in pixels. You can specify another name with an ImgResizeWidthParam directive.

=head2 h

height in pixels. BYou can specify another name with an ImgResizeHeightParam directive.

=head2 reshape

If this is 'crop', we will crop without resizing. The default behaviour is to scale first and then crop to fit the other dimension (see below). If only one dimension is specified, this parameter has no effect. There will be more options here in later versions.

=head2 cropto

This can be left, right, top or bottom, and it dictates the part of the picture that is kept when we crop the image. If only one dimension is specified, this parameter has no effect. Future versions will allow combinations of these values.

=head2 quality

This should be an integer between 0 and 100. It only affects jpeg images. The default is 60. 

=head1 CONFIGURATION

In many cases, this will suffice:

  <Location "/images">
	PerlFixupHandler  Apache::Imager::Resize
  </Location>

But you can also include one or more of these directives to modify the behaviour of the handler:

=head2 ImgResizeCacheDir

Sets the path to a directory that will be used to hold the resized versions of image files. If you don't include this directive, resized images will be stored next to their originals. The supplied value should be relative to your document root, eg:

  <Location "/images">
	PerlFixupHandler  Apache::Imager::Resize
    ImgResizeCacheDir '/images/cache'
  </Location>
  
You can put the cache inside a directory that is handled by AIR without ill effects, though of course it will get a bit odd if you start serving images directly from the cache.
  
=head2 ImgResizeNoCache

If true, this will mean that images are resized for each request and no attempt is made to keep a copy for future use.

=head2 ImgResizeWidthParam

Sets the name of the parameter that will be used to specify the width (in pixels) of the returned image. Default is 'w'.

=head2 ImgResizeHeightParam

Sets the name of the parameter that will be used to specify the height (in pixels) of the returned image. Default is 'h'.

=head1 IMAGE FORMATS

We can work with any image format that L<Imager> can read, which includes all the usual web files and most other bitmaps.

=head1 SHRINKING RULES*

If only one dimension is specified, we will scale the image to that size, keeping the aspect ratio.

If both dimensions are specified and the combination preserves the aspect ratio of the image, we scale the image to that size.

If there is no 'reshape' parameter, and the specified dimensions result in a change of shape, we will first scale the image to the correct size in the dimension that is changing less, then crop in the other dimension to achieve the right shape and size without distorting the image. You can supply a 'cropto' parameter to specify which part of the image is kept in the cropping step.

If the reshape parameter is 'crop', we will crop in both dimensions without scaling the image at all. You can supply a 'cropto' parameter to specify which part of the image is kept. This is likely to yield better quality than scaling, when the original size is close to the target size, but will have less useful results where they're very different.

* You can scale images up, too, but it's not going to be nice.

=head1 CACHING AND EFFICIENCY

Unless you've switched the cache off, the handler keeps a copy of every resized file. When a request comes in, we look first for a cached file, and check that it's no older than the original image file.

By default we keep the cache files next to the originals, which can get messy. You can also specify a cache directory, in which the directory structure of your site will be partly recreated as resized images are stored in subdirectories corresponding to the position of their originals in the main filing system. This makes it much easier to prune or discard the cache.

Note that at the moment it is assumed that your image cache will be within your document root. There's no reason why it should have to be, so at some point soon it will be possible to specify a whole page.

Either way, this request:

  <img src="/images/morecambe.jpg?w=120&h=150&cropto=left">

will produce (or use) a cache file named:

  [cachedir]/images/morecambe_120_150_left.jpg
  
If either dimension is not specified, as is common, the filename will have an x in that position. The cropto parameter is also usually omitted, so this:

  <img src="/images/morecambe.jpg?w=120">

corresponds to this:

  [cachedir]/images/morecambe_120_x.jpg

If neither width nor height is specified we bail out immediately, so the original image will be returned.

There is currently no mechanism for cache cleanup, but we do touch the access date of each file each time it's used (leaving the modification date alone so that it can be to compare with the original file). You could fairly easily set up a cron job to go through your cache directory deleting all the image files that have not been touched for a week or so.

=cut

sub handler {
	my $r = shift;
	my $filename = $r->filename;

	# for now we can manage quite well without libapreq
	# and might soon work under mod_perl 2, even

    my (%args) = $r->args;
	
	# pick up configuration directives via Apache::ModuleConfig

	my $cfg = Apache::ModuleConfig->get($r);
    my $nocache = $cfg->{ImgResizeNoCache};
    my $cachedir = $cfg->{ImgResizeCacheDir};
    my $widthparm = $cfg->{ImgResizeWidthParam} || 'w';
    my $heightparm = $cfg->{ImgResizeHeightParam} || 'h';
    
    # read basic input
    
	my $w = int( $args{$widthparm} );
	my $h = int( $args{$heightparm} );
	return OK unless $w || $h;

	my $cropto = $args{cropto};
	my $reshape = $args{reshape};
	my $quality = $args{quality} || '60';
	
	my ($shrunk, %scale, %crop);
	my ($name, $path, $suffix) = File::Basename::fileparse( $filename, '\.\w{2,5}' );

	unless ($nocache) {	
		my $docroot = $r->document_root;
		
		# interpolate the name of the cache directory if it has been supplied
		
		$path =~ s/^$docroot/$docroot\/$cachedir/ if $cachedir;
		$path =~ s/\/\//\//;
		$shrunk = $path . $name . '_' . ( $w || 'x' ) . '_' . ( $h || 'x' );

		if ($reshape eq 'crop') {
			$shrunk .= '_crop';			
		}
		
		if ($cropto && $cropto =~ /^(left|right|top|bottom)$/i) {
			$shrunk .= "_$cropto";
		}
		
		$shrunk .= $suffix;
		
		if (file_ok( $shrunk, $filename )) {
			$r->filename($shrunk);
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
		
	my $imgwidth = $im->getwidth;
	my $imgheight = $im->getheight;
	
    if ($w && $h) {
    	if ($reshape eq 'crop') {
    		%scale = ();
				
        } else {
			# Imager automatically resizes to make the larger image specified by the two dimensions
			$scale{xpixels} = $w;
			$scale{ypixels} = $h;
        }

    } elsif ($w) {
        $scale{xpixels} = $w;

    } else {
        $scale{ypixels} = $h;
    }
	
	# first we scale the image, if any scale parameters have been set.
	
	$im = $im->scale( %scale ) if %scale;

    if ($w && $h) {
	
		# $dw and $dh are the multipliers by which each dimension is changing
		
		my $dw = $imgwidth / $w if $w;
		my $dh = $imgheight / $h if $h;
		
		# cropto should really be a list parameter so that we can choose top left
		
		if ($reshape eq 'crop') {
			if ($cropto eq 'left') {
				$crop{left} = 0;
				$crop{width} = $w;
				$crop{height} = $h;
				
			} elsif ($cropto eq 'right') {
				$crop{right} = $imgwidth;
				$crop{width} = $w;
				$crop{height} = $h;
				
			} elsif ($cropto eq 'top') {
				$crop{top} = 0;
				$crop{width} = $w;
				$crop{height} = $h;
				
			} elsif ($cropto eq 'bottom') {
				$crop{bottom} = $imgheight;
				$crop{width} = $w;
				$crop{height} = $h;
				
			} else {
				$crop{width} = $w;
				$crop{height} = $w;
			}

		} elsif ($dw > $dh) {
		
			if ($cropto eq 'left') {
				$crop{left} = 0;
				$crop{width} = $w;
			} elsif ($cropto eq 'right') {
				$crop{right} = $im->getwidth;
				$crop{width} = $w;
			} else {
				$crop{width} = $w;
			}

		} elsif ($dh > $dw) {
	
			if ($cropto eq 'top') {
				$crop{top} = 0;
				$crop{height} = $h;
			} elsif ($cropto eq 'bottom') {
				$crop{bottom} = $im->getheight;
				$crop{height} = $h;
			} else {
				$crop{height} = $h;
			}
		}
		
		# if dw == dh, no cropping is required.
		# then we scale the image, if any resizing remains to be done
		
		$im = $im->crop( %crop ) if %crop;
	}

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
		
		$r->header_out('Content-Length', length($imagedata));
		$r->content_type("image/$type");
		$r->send_http_header;
		$r->print($imagedata);
		return OK;
	
	# otherwise we write out the cache file and tell the request to use that filename
	
	} else {
	
		$im->write( 
			file => $shrunk,
			jpegquality => $quality,
		) or return fail("Cannot write $shrunk: " . $im->errstr);
		
		$r->filename($shrunk);
		return OK;
	}
}

# file_ok tests whether the given file exists and is useable
# you can also supply the original file path as a second parameter: in that case
# we will test whether the original is newer than our file, and reject the file if it is

sub file_ok {
	my ($filename, $original) = @_;
	return unless -e $filename;
	return unless -r _;
	return unless -s _;
	return if $original && -M _ > -M $original;		# nb. this is age, not time
	return 1;
}

# a general purpose and rather feeble error handler. This should log through the request, at least.

sub fail {
	my $message = shift;
	my ($package, $filename, $line) = caller;
	warn "$message at $package line $line\n";
	return SERVER_ERROR;
}

# these are just the directive stubs. The definitions are in the Makefile.

sub ImgResizeCacheDir ($$$) {
	my ($cfg, $parms, $path) = @_;
	$cfg->{ImgResizeCacheDir} = $path;
}

sub ImgResizeWidthParam ($$$) {
	my ($cfg, $parms, $label) = @_;
	$cfg->{ImgResizeWidthParam} = $label;
}

sub ImgResizeHeightParam ($$$) {
	my ($cfg, $parms, $label) = @_;
	$cfg->{ImgResizeHeightParam} = $label;
}

sub ImgResizeNoCache ($$$) {
	my ($cfg, $parms, $flag) = @_;
	$cfg->{ImgResizeNoCache} = $flag;
}

=head1 BUGS

No doubt. Reports in rt.cpan.org would be much appreciated.

=head1 TODO

=over

=item * Allow absolute image cache path

=item * Greater compatibility with Apache::ImageMagick cache, so that we can use their proxy module to avoid fat-server calls

=item * Accept more than one cropto parameter, eg top and left.

=item * More reshape parameters, such as stretch (instead of cropping)

=item * the rest of Apache::Imager

=item * tests

=back

=head1 SEE ALSO

L<Imager> L<Apache> L<Apache::ImageMagick> L<Apache::ImageShoehorn> L<Apache::GD::Thumbnail >

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2005 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

