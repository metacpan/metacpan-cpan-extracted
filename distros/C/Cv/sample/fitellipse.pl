#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

########################################################################
#
#  This program is demonstration for ellipse fitting. Program finds 
#  contours and approximate it by ellipses.
#
#  Trackbar specify threshold parametr.
#
#  White lines is contours. Red lines is fitting ellipses.
#
#
#  Autor:  Denis Burenkov.
#
########################################################################

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

my $FITELLIPSE2 = 1;

# Load the source image. HighGUI use.
my $filename = @ARGV > 0? shift : dirname($0).'/'."stuff.jpg";

# load image and force it to be grayscale
my $image = Cv->loadImage($filename, CV_LOAD_IMAGE_GRAYSCALE)
    or die "$0: can't loadimage $filename\n";
    
# Create windows.
my $swin = "Source";
Cv->NamedWindow($swin, 1);
$image->ShowImage($swin);

# Create toolbars. HighGUI use.
my $rwin = "Result";
Cv->NamedWindow($rwin, 1);
Cv->CreateTrackbar("Threshold", $rwin, my $slider_pos = 70, 255, \&process_image);
&process_image;

# Wait for a key stroke; the same function arranges events processing
while (1) {
	my $c = Cv->waitKey;
	$c &= 0xffff if $c >= 0;
	last if $c == 27;
}

exit 0;

# Define trackbar callback functon. This function find contours, draw
# it and approximate it by ellipses.

sub process_image {
	# Create dynamic structure
	my $stor = Cv::MemStorage->new;

	# Threshold the source image. This needful for cvFindontours().
	$image->Threshold(my $bimage = $image->new($image->sizes, CV_8UC1),
					  $slider_pos, 255, CV_THRESH_BINARY);
	$bimage->show($rwin);

	# Find all contours.
	$bimage->findContours(
		$stor, my $contours, &CV_SIZEOF('CvContour'), 
		CV_RETR_LIST, CV_CHAIN_APPROX_NONE,
		);

	# Clear images. IPL use.
	my $cimage = $bimage->new(CV_8UC3)->zero;

	# This cycle draw all contours and approximate it by ellipses.
	for ( ; $contours; $contours = $contours->h_next) {
		my $count = $contours->total; # This is number point in contour

		# Number point must be more than or equal to 6 (for cvFitEllipse_32f).
		next if ($count < 6);

		my $box;
		if ($FITELLIPSE2) {
			# Fits ellipse to current contour.
			$box = $contours->fitEllipse;
		} else {
			# Get contour point set.
			$contours->cvtSeqToArray(\my @points, &CV_WHOLE_SEQ);

			# Fits ellipse to current contour.
			$box = Cv->fitEllipse(@points);
		}

		# Draw current contour.
		$cimage->DrawContours( 
			$contours, cvScalarAll(255), cvScalarAll(255), 0, 1, 8);

		# Convert ellipse data and draw it.
		$cimage->ellipseBox(
			$box, cvScalar(0, 0, 255), 1, &CV_AA
			);
		$cimage->ellipse(
			$box->[0], # center
			[ map { $_ / 2 } @{$box->[1]} ], # axes
			$box->[2], # angle
			0, 360,
			cvScalar(0, 255, 255), 1, &CV_AA,
			);
		$cimage->polyLine(
			[[Cv->boxPoints($box)]], -1, cvScalar(0, 255, 0), 1, &CV_AA
			);
	}
    
	# Show image. HighGUI use.
	$cimage->show($rwin);
}
