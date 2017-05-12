package AxKit::App::Gallery::Plugin;

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
#    documentation and/or other materials provided with the distribution.
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
# $Id: Plugin.pm,v 1.5 2003/11/09 12:33:21 nik Exp $

use strict;
use Apache::Constants qw(OK DECLINED);
use Apache::Request;
use URI;
use URI::Escape;
use Imager;				# Scaling
use Image::Info;			# For width/height

# The job here is two-fold. First, to decide if AxKit should process this
# resource (and thus return OK), second, if it shouldn't process the
# resource, and a jpeg should be created, then to create the jpeg, cache
# it, set $r->filename() to the location of the cached jpeg, and then
# return DECLINED.

sub handler {
	my $r = Apache::Request->new(shift);

#	$r->log_error('In the plugin handler');
#	$r->log_error('args: ' . $r->args());

	# Always return OK for a directory
#	$r->log_error('Checking to see if it\'s a directory: ' . $r->filename());
	return OK if -d $r->filename();

	return OK unless substr($r->content_type(), 0, 6) eq 'image/';

#	$r->log_error('Filename is: ' . $r->filename());

	my $format = $r->param('format');
#	$r->log_error("Format param was $format");
	# If no format parameter was passed in then AxKit can process the URI
	# If the format param is 'html' then AxKit can process the URI
	return OK if ! defined $format;
	return OK if $format eq 'html';

#	$r->log_error('Filename is: ' . $r->filename());

	# Make sure the specified size is one we're configured to
	# support.  If it isn't then use the default size
	my $sizelist = $r->dir_config('GallerySizes');
	$sizelist = '133 640 800 1024' unless defined $sizelist;
	my @sizes = split(/\s+/, $sizelist);
	my $size = $r->param('size');
	if($size eq 'thumb') {
		$size = $sizes[0];
	} else {
		$size = $sizes[1] unless grep { $_ eq $size } @sizes;
	}

	# Get the larger of the image's width and height.  If this is smaller than
	# the size user has requested, change the size to 'full'
	# XXX should write code to do this

#	$r->log_error("New size is $size");
#	$r->log_error('Filename is: ' . $r->filename());

	# If the size is 'full' then we're sending back the full size
	# image.  There's no work to do, so just return DECLINED
	return DECLINED if $size eq 'full';

	# Now we know what size the image should be, check to see if a
	# cached copy already exists.
	my $cache_dir = $r->dir_config('GalleryCache');
#	my $uri = URI->new($r->uri());
#	my $cachepath = "$cache_dir/$uri";
	my $cachepath = $cache_dir . $r->filename();

	my $cachedfile = "$cachepath/$size.jpg";
	$cachedfile = uri_unescape($cachedfile);

#	$r->log_error("Cachedfile is $cachedfile");

	my $image = Imager->new();

	if(! -f $cachedfile
	    || -z $cachedfile
	    || (stat($r->filename()))[9] > (stat($cachedfile))[9]) {	
#		$r->log_error("will open " . $r->filename());

		$image->open(file => $r->filename())
			or die $image->errstr();

#		$r->log_error("opened original image");

		my($w, $h) = ($image->getwidth(), $image->getheight());

		my $quality = $r->dir_config('GalleryThumbQuality');
		$quality = 'normal' if $quality ne 'preview';
			
		my $thumb = $image->scale(qtype => $quality, 
	  	    $w > $h 
		        ? (xpixels => $size)
		        : (ypixels => $size));

#		$r->log_error("scaled image");

		$thumb->write(file => $cachedfile);
	
#		$r->log_error("Wrote scaled image to $cachedfile");
	}

	$r->filename($cachedfile);
	return DECLINED;
}

1;
