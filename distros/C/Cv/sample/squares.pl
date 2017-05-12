#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

# The full "Square Detector" program.  It loads several images
# subsequentally and tries to find squares in each image

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;
use Data::Dumper;

my $thresh = 50;
my $wndname = "Square Detection Demo";

# helper function: finds a cosine of angle between vectors from
# pt0->pt1 and from pt0->pt2

sub angle {
	my ($pt1, $pt2, $pt0) = @_;

	my $dx1 = $pt1->[0] - $pt0->[0];
	my $dy1 = $pt1->[1] - $pt0->[1];
	my $dx2 = $pt2->[0] - $pt0->[0];
	my $dy2 = $pt2->[1] - $pt0->[1];

    ($dx1*$dx2 + $dy1*$dy2) /
		sqrt(($dx1*$dx1 + $dy1*$dy1)*($dx2*$dx2 + $dy2*$dy2) + 1e-10);
}


# create memory storage that will contain all the dynamic data
my $storage = Cv::MemStorage->new(0);

# returns sequence of squares detected on the image.  the sequence is
# stored in the specified memory storage

sub findSquares4 {
	my $img = shift;

	my $N = 11;

	# create empty sequence that will contain points - 4 points per
	# square (the square's vertices)

	my @squares = ();

	# select the maximum ROI in the image with the width and height
	# divisible by 2

	my $sz = [ $img->width & -2, $img->height & -2 ];
	(my $timg = $img->clone) # make a copy of input image
		->roi([ 0, 0, @$sz ]);

	# down-scale and upscale the image to filter out the noise
	# $timg = $timg->pyrDown(7)->pyrUp(7);
	$timg->pyrDown(7)->pyrUp($timg, 7);

	# find squares in every color plane of the image
	foreach my $c (1 .. 3) {

		# extract the c-th color plane
		$timg->coi($c);
		my $tgray = $timg->copy($timg->new($timg->sizes, CV_8UC1));

		# try several threshold levels
		foreach my $l (0 .. $N - 1) {
			# hack: use Canny instead of zero threshold level.
			# Canny helps to catch squares with gradient shading   

			my $gray;

			if ($l == 0) {
				# apply Canny. Take the upper threshold from slider
				# and set the lower to 0 (which forces edges merging)

				$gray = $tgray->canny(0, $thresh, 5)

					# dilate canny output to remove potential holes
					# between edge segments

					->dilate;

			} else {
				# apply threshold if l!=0:
				#   tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0

				$tgray->threshold(
					$gray = $tgray->new, ($l + 1)*255/$N, 255,
					CV_THRESH_BINARY);
            }

			# find contours and store them all as a list
			$gray->findContours($storage, my $contour);
			next unless $contour;

			# test each contour
			while ($contour) {

				# approximate contour with accuracy proportional to
				# the contour perimeter

				my $result = bless $contour->approxPoly(
					$contour->header_size, $storage, CV_POLY_APPROX_DP,
					$contour->contourPerimeter * 0.02,
					), 'Cv::Seq::Point';

				# square contours should have 4 vertices after
				# approximation relatively large area (to filter out
				# noisy contours) and be convex.

				# Note: absolute value of an area is used because area
				# may be positive or negative - in accordance with the
				# contour orientation

				if ($result->total == 4 &&
					abs($result->contourArea) > 1000 &&
					$result->checkContourConvexity) {

					my $s = 0;

					foreach my $i (2 .. 4) {

						# find minimum angle between joint edges
						# (maximum of cosine)
						
						my $t = abs(
							angle(
								map {
									scalar $result->getSeqElem($_)
								} ($i, $i - 2, $i - 1)
							));
						$s = $s > $t ? $s : $t;
                    }

					# if cosines of all angles are small (all angles
					# are ~90 degree) then write quandrange vertices
					# to resultant sequence

					if ($s < 0.3) {
						push(@squares, [
								 map {
									 scalar $result->getSeqElem($_)
								 } (0..3)
							 ]);
					}
                }
				
				# take the next contour
				$contour = $contour->h_next;
			}
        }
    }

	@squares;
}



my @names = ("pic1.png", "pic2.png", "pic3.png",
			 "pic4.png", "pic5.png", "pic6.png");

foreach my $name (@names) {
	# load i-th image
	my $img0 = Cv->loadImage(dirname($0) . "/$name", 1);
	unless ($img0) {
		print "Couldn't load $name\n";
		next;
    }

	my $img = $img0->clone;

	use Time::HiRes qw(gettimeofday);
	my $t0 = gettimeofday;

	# find and draw the squares
    my $cpy = $img->clone;
	$cpy->polyLine([&findSquares4($img)], -1, [ 0, 255, 0 ], 3);

	my $t1 = gettimeofday;
	print STDERR "time = ", $t1 - $t0, "\n";

    $cpy->show($wndname);
	
    # wait for key.  Also the function cvWaitKey takes care of event
    # processing
	my $c = Cv->waitKey(0);
    last if ($c > 0 && ($c & 0xff) == 27);
}

exit 0;
