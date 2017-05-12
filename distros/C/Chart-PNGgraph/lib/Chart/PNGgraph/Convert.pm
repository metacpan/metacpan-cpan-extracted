#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		Chart::PNGgraph::Convert.pm
#
# $Id: Convert.pm,v 1.1.2.1 2000/04/05 02:51:59 sbonds Exp $
#
#==========================================================================
package Chart::PNGgraph::Convert;

use strict;
use Carp;

# Change this sub if you want to use something else to convert from GIF
# to PNG.
sub gif2png
{
	my $gif  = shift;

	checkImageMagick();

	my $im = Image::Magick->new(magick => 'gif') or 
		croak 'Cannot create Image::Magick object';
	my $rc = $im->BlobToImage($gif);
	carp $rc if $rc;
	$rc = $im->Set(magick => 'png');
	return $im->ImageToBlob();
}

sub checkImageMagick
{
	eval "require Image::Magick";
	croak <<EOMSG if $@;

	Image::Magick cannot be found. Your version of GD exports GIF format
	graphics, and Chart:PNGgraph needs something to convert those to
	PNG. If you want to provide an alternative method, please edit the
	sub gif2png in the file Chart/PNGgraph/Convert.pm, and if you're
	installing, Makefile.PL.

EOMSG
}

1;
