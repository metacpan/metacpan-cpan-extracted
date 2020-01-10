package Dancer::Plugin::Thumbnail;

=head1 NAME

Dancer::Plugin::Thumbnail - Easy thumbnails creating with Dancer and GD

=cut

use Dancer ':syntax';
use Dancer::MIME;
use Dancer::Plugin;
use GD::Image;
use JSON::MaybeXS;
use List::Util qw( min max );
use Object::Signature;
use POSIX 'strftime';


=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';


=head1 SYNOPSIS

 use Dancer;
 use Dancer::Plugin::Thumbnail;

 # simple resize
 get '/resized/:width/:image' => sub {
     resize param('image') => { w => param 'width' };
 }

 # simple crop
 get '/cropped/:width/:image' => sub {
     crop param('image') => { w => param 'width' };
 }

 # more complex
 get '/thumb/:w/:h/:image' => sub {
     thumbnail param('image') => [
         crop   => { w => 200, h => 200, a => 'lt' },
         resize => { w => param('w'), h => param('h'), s => 'min' },
     ], { format => 'jpeg', quality => 90 };
 }


=head1 METHODS

=head2 thumbnail ( $file, \@operations, \%options )

Makes thumbnail image from original file by chain of graphic operations.
Image file name may be an absolute path or relative from config->{'public'}.
Each operation is a reference for two elements array. First element
is an operation name (currently supported 'resize' and 'crop') and second is
operation arguments as hash reference (described in appropriate operation
section).

After operations chain completed final image creates with supplied options:

=over

=item cache

Directory name for storing final results. Undefined setting (default) breaks
caching and isn't recommended for any serious production usage. Relative
cache directory will be prefixed with config->{'appdir'} automatically.
Cache path is generated from original file name, its modification time,
operations with arguments and an options. If you are worried about cache
garbage collecting you can create a simple cron job like:

 find /cache/path -type f -not -newerat '1 week ago' -delete

=item format

Specifies output image format. Supported formats are 'gif', 'jpeg' and 'png'.
Special format 'auto' (which is default) creates the same format as original
image has.

=item compression

PNG compression level. From '0' (no compression) to '9' (maximum).
Default is '-1' (default GD compression level for PNG creation).

=item quality

JPEG quality specifications. From '0' (the worse) to '100' (the best).
Default is 'undef' (default GD quality for JPEG creation).

=back

Defaults for these options can be specified in config.yml:

 plugins:
     Thumbnail:
         cache: var/cache
         compression: 7
         quality: 50

=cut

sub thumbnail {
	my ( $file, $opers, $opts ) = @_;

	# load settings
	my $conf = plugin_setting;

	# file argument is required
	unless ( $file ) {
		status 404;
		return '404 Not Found';
	}

	# create an absolute path
	$file = path config->{ public }, $file
		unless $file =~ m{^/};

	# check for file existance and readabilty
	unless ( -f $file && -r _ ) {
		status 404;
		return '404 Not Found';
	}

	# try to get stat info
	my @stat = stat $file or do {
		status 404;
		return '404 Not Found';
	};

	# prepare Last-Modified header
	my $lmod = strftime '%a, %d %b %Y %H:%M:%S GMT', gmtime $stat[9];

	# processing conditional GET
	if ( ( header('If-Modified-Since') || '' ) eq $lmod ) {
		status 304;
		return;
	}

	# target format & content-type
	my $mime = Dancer::MIME->instance;
	my $fmt = $opts->{ format } || $conf->{ format } || 'auto';
	my $type = $fmt eq 'auto' ?
		$mime->for_file( $file ) :
		$mime->for_name( $fmt )
	;
	( $fmt ) = $type->extensions
		if $fmt eq 'auto';

	# target options
	my $compression = $fmt eq 'png' ?
		defined $opts->{ compression } ? $opts->{ compression } :
		defined $conf->{ compression } ? $conf->{ compression } :
		-1 : 0;
	my $quality = $fmt eq 'jpeg' ?
		( exists $opts->{ quality } ?
			$opts->{ quality } :
			$conf->{ quality } ) :
			undef;

	# try to resolve cache directory
	my $cache_dir = exists $opts->{ cache } ? $opts->{ cache } : $conf->{ cache };

	if ( $cache_dir ) {
		# check for an absolute path of cache directory
		$cache_dir = path config->{ appdir }, $cache_dir
			unless $cache_dir =~ m{^/};

		# check for existance of cache directory
		unless ( -d $cache_dir && -w _ ) {
			warning "no cache directory at '$cache_dir'";
			undef $cache_dir;
		}
	}

	# cache path components
	my ( $cache_key,@cache_hier,$cache_file );
	if ( $cache_dir ) {
		# key should include file, operations and calculated defaults
		$cache_key = Object::Signature::signature(
			[ $file,$stat[9],$opers,$quality,$compression ]
		);
		@cache_hier = map { substr $cache_key,$_->[0],$_->[1] } [0,1],[1,2];
		$cache_file = path $cache_dir,@cache_hier,$cache_key;

		# try to get cached version
		if ( -f $cache_file ) {
			open FH, '<:raw', $cache_file or do {
				error "can't read cache file '$cache_file'";
				status 500;
				return '500 Internal Server Error';
			};

			# skip meta info
			local $/ = "\n\n"; <FH>; undef $/;

			# send useful headers & content
			content_type $type->type;
			header 'Last-Modified'  => $lmod;
			return scalar <FH>;
		}
	}

	# load source image
	my $src_img = GD::Image->new( $file ) or do {
		error "can't load image '$file'";
		status 500;
		return '500 Internal Server Error';
	};

	# original sizes
	my ($src_w,$src_h) = $src_img->getBounds;

	# destination image and its serialized form
	my ($dst_img,$dst_bytes);

	# trasformations loop
	for ( my $i=0; $i<$#$opers; $i+=2 ) {
		# next task and its arguments
		my ($op,$args) = @$opers[$i,$i+1];

		# target sizes
		my $dst_w = $args->{ w } || $args->{ width };
		my $dst_h = $args->{ h } || $args->{ height };

		for ( $op ) {
			if ( $_ eq 'resize') {
				my $scale_mode = $args->{ s } || $args->{ scale } || 'max';
				do {
					error "unknown scale mode '$scale_mode'";
					status 500;
					return '500 Internal Server Error';
				} unless $scale_mode eq 'max' || $scale_mode eq 'min';

				# calculate scale
				no strict 'refs';
				my $scale = &{ $scale_mode }(
					grep { $_ } $dst_w && $src_w/$dst_w,
					            $dst_h && $src_h/$dst_h
				);
				$scale = max $scale,1;

				# recalculate target sizes
				($dst_w,$dst_h) = map { sprintf '%.0f',$_/$scale } $src_w,$src_h;

				# create new image
				$dst_img = GD::Image->new($dst_w,$dst_h,1) or do {
					error "can't create image for '$file'";
					status 500;
					return '500 Internal Server Error';
				};

				# resize!
				$dst_img->copyResampled( $src_img,0,0,0,0,
					$dst_w,$dst_h,$src_w,$src_h
				);
			}
			elsif ( $_ eq 'crop' ) {
				$dst_w = min $src_w, $dst_w || $src_w;
				$dst_h = min $src_h, $dst_h || $src_h;

				# anchors
				my ($h_anchor,$v_anchor) =
					( $args->{ a } || $args->{ anchors } || 'cm' ) =~
					/^([lcr])([tmb])$/ or do {
					error "invalid anchors: '$args->{ anchors }'";
					status 500;
					return '500 Internal Server Error';
				};

				# create new image
				$dst_img = GD::Image->new($dst_w,$dst_h,1) or do {
					error "can't create image for '$file'";
					status 500;
					return '500 Internal Server Error';
				};

				# crop!
				$dst_img->copy( $src_img,0,0,
					sprintf('%.0f',
						$h_anchor eq 'l' ? 0 :
						$h_anchor eq 'c' ? ($src_w-$dst_w)/2 :
						$src_w - $dst_w
					),
					sprintf('%.0f',
						$v_anchor eq 't' ? 0 :
						$v_anchor eq 'm' ? ($src_h-$dst_h)/2 :
						$src_h - $dst_h
					),
					$dst_w,$dst_h
				);
			}
			else {
				error "unknown operation '$op'";
				status 500;
				return '500 Internal Server Error';
			}
		}

		# keep destination image as original
		($src_img,$src_w,$src_h) = ($dst_img,$dst_w,$dst_h);
	}

	# generate image
	for ( $fmt ) {
		if ( $_ eq 'gif' ) {
			$dst_bytes = $dst_img->$_;
		}
		elsif ( $_ eq 'jpeg' ) {
			$dst_bytes = $quality ? $dst_img->$_( $quality ) : $dst_img->$_;
		}
		elsif ( $_ eq 'png' ) {
			$dst_bytes = $dst_img->$_( $compression );
		}
		else {
			error "unknown format '$_'";
			status 500;
			return '500 Internal Server Error';
		}
	}

	# store to cache (if requested)
	if ( $cache_file ) {
		# create cache subdirectories
		for ( @cache_hier ) {
			next if -d ( $cache_dir = path $cache_dir,$_ );
			mkdir $cache_dir or do {
				error "can't create cache directory '$cache_dir'";
				status 500;
				return '500 Internal Server Error';
			};
		}
		open FH, '>:raw', $cache_file or do {
			error "can't create cache file '$cache_file'";
			status 500;
			return '500 Internal Server Error';
		};
		# store serialized meta information (for future using)
		print FH encode_json({
			args    => \@_,
			compression => $compression,
			conf    => $conf,
			format  => $fmt,
			lmod    => $lmod,
			mtime   => $stat[9],
			quality => $quality,
			type    => $type->type,
		}) . "\n\n";
		# store actual target image
		print FH $dst_bytes;
	}

	# send useful headers & content
	content_type $type->type;
	header 'Last-Modified'  => $lmod;
	return $dst_bytes;
}

register thumbnail => \&thumbnail;


=head2 crop ( $file, \%arguments, \%options )

This is shortcut (syntax sugar) fully equivalent to call:

thumbnail ( $file, [ crop => \%arguments ], \%options )

Arguments includes:

=over

=item w | width

Desired width (optional, default not to crop by horizontal).

=item h | height

Desired height (optional, default not to crop by vertical).

=item a | anchors

Two characters string which indicates desired fragment of original image.
First character can be one of 'l/c/r' (left/right/center), and second - 't/m/b'
(top/middle/bottom). Default is 'cm' (centered by horizontal and vertical).

=back

=cut

register crop => sub {
	thumbnail shift, [ crop => shift ], @_;
};


=head2 resize ( $file, \%arguments, \%options )

This is shortcut and fully equivalent to call:

thumbnail ( $file, [ resize => \%arguments ], \%options )

Arguments includes:

=over

=item w | width

Desired width (optional, default not to resize by horizontal).

=item h | height

Desired height (optional, default not to resize by vertical).

=item s | scale

The operation always keeps original image proportions.
Horizontal and vertical scales calculates separately and 'scale' argument
helps to select maximum or minimum from "canditate" values.
Argument can be 'min' or 'max' (which is default).

=back

=cut


register resize => sub {
	thumbnail shift, [ resize => shift ], @_;
};


register_plugin;


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg at mamontov.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-thumbnail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Thumbnail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Thumbnail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Thumbnail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Thumbnail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Thumbnail>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Thumbnail/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Oleg A. Mamontov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;

