#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

my $filename = @ARGV > 0 ? shift : dirname($0).'/'."fruits.jpg";
my $image = Cv->LoadImage($filename, CV_LOAD_IMAGE_COLOR) or 
	die "Image was not loaded.\n";

# Convert to grayscale
my $gray = $image->CvtColor(CV_BGR2GRAY);
my $edge = Cv::Image->new($image->sizes, CV_MAKETYPE(CV_8U, 1));

# Create the output image
my $cedge = Cv::Image->new($image->sizes, CV_MAKETYPE(CV_8U, 3));

# Create a window
Cv->NamedWindow("Edge");
Cv->CreateTrackbar("Edge", "Threshold", my $edge_thresh = 1, 100, \&on_trackbar);

# Show the image
&on_trackbar;

# Wait for a key stroke; the same function arranges events processing
Cv->WaitKey;

# define a trackbar callback
sub on_trackbar {

    $edge = $gray->Smooth(CV_BLUR, 3, 3);

    # Run the edge detector on grayscale
    $edge = $gray->Canny($edge_thresh, $edge_thresh*3);

    # copy edge points
    $cedge->Zero;
    $image->Copy($cedge, $edge);

    $cedge->ShowImage("Edge");
}
