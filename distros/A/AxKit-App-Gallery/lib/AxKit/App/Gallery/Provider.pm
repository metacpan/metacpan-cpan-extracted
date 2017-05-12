package AxKit::App::Gallery::Provider;

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
# $Id: Provider.pm,v 1.4 2003/11/09 12:33:44 nik Exp $

use Apache::Constants qw(:common);
use Apache::Request;
use File::Path;
use URI;
use URI::Escape;				# For unescaping URIs
use Apache::AxKit::Provider::File;
use Apache::AxKit::Exception;
#use Data::Dumper;

use base qw(Apache::AxKit::Provider::File);

sub get_fh {
	my $self = shift;
	my $r    = $self->{apache};

#	$r->log_error("get_fh(), r is " . Dumper($r));

	return $self->SUPER::get_fh() 
		unless substr($r->content_type(), 0, 6) eq 'image/';

	my $format = $r->param('format');

#	$r->log_error("get_fh(), format is $format");

	$format = 'raw' unless $format;		# Default format is raw

	# If the format is not 'raw' then generate the XML info for the 
	# image.  That's done by get_strref(), so bail out here
	if($format ne 'raw') {
		AxKit::Debug(5, "Format is not 'raw'");
		throw Apache::AxKit::Exception::IO(
			-text => "Format is not 'raw'");
	}

	return $self->SUPER::get_fh();
}

# Given an image's filename, generate some XML with information about
# just that image.
sub get_strref {
	my $self = shift;
	
	# XXX $self->{apache} seems to be an Apache object, not
	# an Apache::Request object.  So $r->param() doesn't work.  Make
	# sure it's a ::Request object.  No idea why we need to do this
	# here, but not in get_fh() -- maybe we do?
	my $r    = Apache::Request->new($self->{apache});

#	$r->log_error("get_strref() called: file: " . $r->filename() . " type: " . $r->content_type());

#	$r->log_error(Dumper($r));

	return $self->SUPER::get_strref() if ! -f $r->filename();

	$r->content_type('text/xml');

	# Get the filename, extract some stats
	my $file = $r->filename();
#	$r->log_error("stat()ing $file");
	my $filesize = (stat($file))[7];
	my $mod  = (stat(_))[9];

	# Use the filename to retrive the path, and separate out the filename
	my $path;
	($path, $file) = $file =~ /(.*)\/(.*)/;	# Extract the path/file info

	my $uri  = URI->new($r->uri());
	$uri =~ s/^\///;			# Trim the leading '/'
	$uri = join("\n", 
		map { "<component><e>$_</e><u>" . uri_unescape($_) . "</u></component>" } split(/\//, $uri));

	my $ct   = $r->content_type();

	my $xml = <<EOXML;
<?xml version="1.0"?>
<imagesheet>
  <config>
    <perl-vars>
EOXML
	
	foreach my $var (qw(ProofsheetColumns ImagesPerProofsheet
                        GalleryCache GalleryThumbQuality)) {
		$xml .= "<var name='$var'>" . $r->dir_config($var) . "</var>\n";
	}

        my $size = $r->param('size');

        # Make sure the specified size is one we're configured to
        # support.  If it isn't then use the default size
        my $sizelist = $r->dir_config('GallerySizes');
        $sizelist = '133 640 800 1024' unless defined $sizelist;
        my @sizes = split(/\s+/, $sizelist);

        if($size eq 'thumb') {
                $size = $sizes[0];
        } else {
                $size = $sizes[1] unless grep { $_ eq $size } @sizes;
        }

	$xml .= <<EOXML;
<GallerySizes>
  <size type="thumb">$sizes[0]</size>
EOXML
	foreach (@sizes[1..$#sizes]) {
		if($_ == $size) {
			$xml .= "<size type=\"default\">$_</size>\n";
		} else {
			$xml .= "<size>$_</size>\n";
		}
	}
	$xml .= "</GallerySizes>";
	
	$xml .= <<EOXML;
    </perl-vars>
  </config>

  <image>
    <filename>$file</filename>
    <filesize>$filesize</filesize>
    <size>$size</size>
    <modified>$mod</modified>
    <uri>$uri</uri>
    <dirpath>$path</dirpath>
    <content-type>$ct</content-type>
  </image>	
</imagesheet>
EOXML

#	$r->log_error("Provider returning $xml");
	return \$xml;
}

1;
