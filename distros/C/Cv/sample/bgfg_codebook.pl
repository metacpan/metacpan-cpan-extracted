#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
# use warnings;
use lib qw(blib/lib blib/arch);
use Cv -bg;
use List::Util qw(max min);

# Background average sample code done with averages and done with codebooks
# (adapted from the OpenCV book sample)
# 
# NOTE: To get the keyboard to work, you *have* to have one of the
#       video windows be active and NOT the consule window.
#
# Gary Bradski Oct 3, 2008.
# 
# /* *************** License:**************************
# Oct. 3, 2008
# Right to use this code in any way you want without warrenty,
# support or any guarentee of it working.
#
# BOOK: It would be nice if you cited it:
# Learning OpenCV: Computer Vision with the OpenCV Library
#   by Gary Bradski and Adrian Kaehler
#   Published by O'Reilly Media, October 3, 2008
# 
# AVAILABLE AT: 
#   http://www.amazon.com/Learning-OpenCV-Computer-Vision-Library/dp/0596516134
#   Or: http://oreilly.com/catalog/9780596516130/
#   ISBN-10: 0596516134 or: ISBN-13: 978-0596516130    
# ************************************************** */

sub help {
    print STDERR
		"\nLearn background and find foreground using simple average and average difference learning method:\n",
        "\nUSAGE:\nbgfg_codebook [--nframes=300] [movie filename, else from camera]\n",
        "***Keep the focus on the video windows, NOT the consol***\n\n",
        "INTERACTIVE PARAMETERS:\n",
        "\tESC,q,Q  - quit the program\n",
        "\th	- print this help\n",
        "\tp	- pause toggle\n",
        "\ts	- single step\n",
        "\tr	- run mode (single step off)\n",
        "=== AVG PARAMS ===\n",
        "\t-    - bump high threshold UP by 0.25\n",
        "\t=    - bump high threshold DOWN by 0.25\n",
        "\t[    - bump low threshold UP by 0.25\n",
        "\t]    - bump low threshold DOWN by 0.25\n",
        "=== CODEBOOK PARAMS ===\n",
        "\ty,u,v- only adjust channel 0(y) or 1(u) or 2(v) respectively\n",
        "\ta	- adjust all 3 channels at once\n",
        "\tb	- adjust both 2 and 3 at once\n",
        "\ti,o	- bump upper threshold up,down by 1\n",
        "\tk,l	- bump lower threshold up,down by 1\n",
        "\tSPACE - reset the model\n",
		;
}

# USAGE:  ch9_background startFrameCollection# endFrameCollection#
# [movie filename, else from camera]
# If from AVI, then optionally add HighAvg, LowAvg, HighCB_Y LowCB_Y
# HighCB_U LowCB_U HighCB_V LowCB_V

my $nframesToLearnBG = 300;

use Getopt::Long;
unless (GetOptions("--nframes=i" => \$nframesToLearnBG)) {
	help();
	exit(-1);
}

my $capture;
if (@ARGV == 0) {
	warn("Capture from camera 0\n");
    $capture = Cv::Capture->fromCAM(0);
} elsif (@ARGV == 1 && $ARGV[0] =~ /^\d$/) {
	warn("Capture from camera $ARGV[0]\n");
    $capture = Cv::Capture->fromCAM($ARGV[0]);
} else {
	warn("Capture from file $ARGV[0]\n");
    $capture = Cv::Capture->fromFile($ARGV[0]);
}
unless ($capture) {
	warn("Can not initialize video capturing\n\n");
	help;
}

my $rawImage;
my $nframes = 0;

# VARIABLES for CODEBOOK METHOD:
my $model = Cv::BGCodeBookModel->new;
my @ch = (1, 1, 1); # This sets what channels should be adjusted for background bounds
   
# Set color thresholds to default values
$model->modMin([ 3, 3, 3 ]);
$model->modMax([ 10, 10, 10 ]);
$model->cbBounds([ 10, 10, 10 ]);

my $ImaskCodeBook;
my $ImaskCodeBookCC;

my $pause;
my $singlestep;

# MAIN PROCESSING LOOP:
while (1) {
	unless ($pause) {
		$rawImage = $capture->QueryFrame;
		last unless ($rawImage);
		++$nframes;
	}
	$pause = 1 if ($singlestep);

	# First time:
	if ($nframes == 1 && $rawImage) {
		# CODEBOOK METHOD ALLOCATION
		$ImaskCodeBook = Cv::Image->new($rawImage->sizes, CV_8UC1);
		$ImaskCodeBookCC = Cv::Image->new($rawImage->sizes, CV_8UC1);
		$ImaskCodeBook->fill(cvScalar(255));

		Cv->NamedWindow("Raw", 0);
		Cv->NamedWindow("ForegroundCodeBook", 0);
		Cv->NamedWindow("CodeBook_ConnectComp", 0);
	}

	# If we've got an rawImage and are good to go:
	if ($rawImage) {
		# YUV For codebook method
		my $yuvImage = $rawImage->CvtColor(CV_BGR2YCrCb);

		# This is where we build our background model
		if (!$pause && $nframes - 1 < $nframesToLearnBG) {
			$model->update($yuvImage);
		}
		if ($nframes - 1 == $nframesToLearnBG) {
			$model->clearStale($model->t / 2);
		}

		# Find the foreground if any
		if ($nframes - 1 >= $nframesToLearnBG) {
			# Find foreground by codebook method
			$model->diff($yuvImage, $ImaskCodeBook);

			# This part just to visualize bounding boxes and centers
			# if desired
			$ImaskCodeBook->copy($ImaskCodeBookCC);
			$ImaskCodeBookCC->SegmentFGMask;
		}

		# Display
		$rawImage->show("Raw");
		$ImaskCodeBook->show("ForegroundCodeBook");
		$ImaskCodeBookCC->show("CodeBook_ConnectComp");
	}
	
	# User input:
	next if (my $c = Cv->WaitKey(10)) < 0;
	$c = lc(chr($c & 0xff));

	# End processing on ESC, q or Q
	if ($c == "\e" || $c eq 'q') {
		last;
	}
	# Else check for user input
	elsif ($c eq 'h') {
		help();
	}
	elsif ($c eq 'p') {
		$pause = !$pause;
	}
	elsif ($c eq 's') {
		$singlestep = !$singlestep;
		$pause = 0;
	}
	elsif ($c eq 'r') {
		$singlestep = 0;
		$pause = 0;
	}
	elsif ($c eq ' ') {
		$model->clearStale(0);
		$nframes = 0;
	}

	# CODEBOOK PARAMS
	elsif ($c =~ /[yuvab123]/) {
		$ch[0] = $c =~ /[y0a3]/;
		$ch[1] = $c =~ /[u1a3b]/;
		$ch[2] = $c =~ /[v2a3b]/;
		printf("CodeBook YUV Channels active: %d, %d, %d\n", @ch[0..2]);
	}

	# modify max classification bounds
	elsif ($c eq 'i') {		# max bound goes higher
		$model->modMax([ map { min($_ + 1, 255) } @{$model->modMax}]);
	}
	elsif ($c eq 'o') {		# max bound goes lower
		$model->modMax([ map { max($_ - 1, 0) } @{$model->modMax}]);
	}
	elsif ($c eq 'k') {     # min bound goes lower
		$model->modMin([ map { min($_ + 1, 255) } @{$model->modMin}]);
	}
	elsif ($c eq 'l') {		# min bound goes higher
		$model->modMin([ map { max($_ - 1, 0) } @{$model->modMin}]);
	}
	if ($c =~ /[io]/) {
		printf("%s CodeBook High Side\n", join(', ', @{$model->modMax}));
	}
	if ($c =~ /[kl]/) {
		printf("%s CodeBook Low Side\n", join(', ', @{$model->modMin}));
	}
}		
