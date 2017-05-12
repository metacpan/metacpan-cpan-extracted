#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Time::HiRes qw(gettimeofday);
use Data::Dumper;

# various tracking parameters (in seconds)
use constant {
	MHI_DURATION   => 1,
};

use constant {
	MAX_TIME_DELTA => MHI_DURATION * 0.5,
	MIN_TIME_DELTA => MHI_DURATION * 0.05,
};

# number of cyclic frame buffer used for motion detection
# (should, probably, depend on FPS)
use constant {
	N => 4,
};

my $diff_threshold = 30;

my $start;
my $lastgray;

# temporary images
my $mhi;						# MHI
my $orient;						# orientation
my $mask;						# valid orientation mask
my $segmask;					# motion segmentation map
my $storage;					# temporary storage

# parameters:
#   img - input video frame
#   dst - resultant motion picture
sub update_mhi {
	my ($img, $dst) = @_;
	unless ($start) {
		$start = gettimeofday;
	}
    my $timestamp = gettimeofday - $start; # get current time in seconds
    my $size = cvSize($img->width, $img->height); # get current frame size
	my $gray = $img->CvtColor(CV_BGR2GRAY); # convert frame to grayscale

	unless ($lastgray) {
		$lastgray = $gray;
	}

	unless ($mhi) {
		# temporary images
		$mhi = $gray->new($gray->sizes, CV_32FC1)->Zero;
		$mask = $gray->new;
		$orient = $mhi->new;
		$segmask = $mhi->new;
	}

	# get difference between frames and threshold it
	my $binary = $gray->AbsDiff($lastgray, $gray->new)
		->Threshold($diff_threshold, 1, CV_THRESH_BINARY);
	$binary->UpdateMotionHistory($mhi, $timestamp, MHI_DURATION);
	
	# convert MHI to blue 8u image
	$mhi->CvtScale($mask, 255/MHI_DURATION,
				   (MHI_DURATION - $timestamp)*255/MHI_DURATION);
	$dst->Zero;
	Cv->Merge([$mask], $dst);

	# calculate motion gradient orientation and valid orientation mask
	$mhi->CalcMotionGradient(
		$mask, $orient, MAX_TIME_DELTA, MIN_TIME_DELTA, 3);

	unless ($storage) {
		$storage = Cv::MemStorage->new;
	} else {
		$storage->ClearMemStorage;
	}

	# segment motion: get sequence of motion components segmask is
	# marked motion components map. It is not used further
	my $seq = $mhi->SegmentMotion(
		$segmask, $storage, $timestamp, MAX_TIME_DELTA);

	# iterate through the motion components,
	# One more iteration (i == -1) corresponds to the whole image
	# (global motion)
	foreach my $i (-1 .. $seq->total - 1) {
		my ($comp_rect, $color, $magnitude);
		if ($i < 0) {		# case of the whole image
			$comp_rect = cvRect(0, 0, @$size);
			$color = CV_RGB(255,255,255);
			$magnitude = 100;
		} else {			# i-th motion component
			$comp_rect = [unpack("x8 x32 i4", $seq->GetSeqElem($i))];
			$color = CV_RGB(255,0,0);
			$magnitude = 30;
		}

		# reject very small components
		next if ($comp_rect->[2] + $comp_rect->[3] < 100);

		# select component ROI
		$_->setROI($comp_rect) for ($binary, $mhi, $orient, $mask);

		# calculate orientation
		my $angle = $orient->CalcGlobalOrientation(
			$mask, $mhi, $timestamp, MHI_DURATION,
			);
		$angle = 360.0 - $angle;  # adjust for images with top-left origin
		$angle *= &CV_PI / 180;

		my $count = $binary->Norm(\0, CV_L1, \0);

		$_->resetROI for ($binary, $mhi, $orient, $mask);

		# check for the case of little motion
		next if ($count <= 0);
		next if ($count < $comp_rect->[2] * $comp_rect->[3] * 0.05);
		
		# draw a clock with arrow indicating the direction
		my $center = [ $comp_rect->[0] + $comp_rect->[2] / 2,
					   $comp_rect->[1] + $comp_rect->[3] / 2 ];
		$dst->Circle($center, $magnitude * 1.2, $color, 3, CV_AA);
		$dst->Line($center, [ $center->[0] + $magnitude * cos($angle),
							  $center->[1] - $magnitude * sin($angle) ],
				   $color, 3, CV_AA);
	}

	$lastgray = $gray;
}


my $capture;
if (@ARGV == 0) {
    $capture = Cv::Capture->fromCAM(0);
} elsif (@ARGV == 1 && $ARGV[0] =~ /^\d$/) {
    $capture = Cv::Capture->fromCAM($ARGV[0]);
} else {
    $capture = Cv::Capture->fromFile($ARGV[0]);
}
$capture or die "can't create capture";

Cv->NamedWindow("Motion", 1);
Cv->CreateTrackbar("Diff Threshold", "Motion", $diff_threshold, 255, sub {});

my $motion;
while (my $image = $capture->QueryFrame) {
	unless ($motion) {
		$motion = Cv::Image->new($image->sizes, CV_8UC3);
		$motion->origin($image->origin);
	}
	update_mhi($image, $motion, 30);
	$motion->ShowImage("Motion");
	last if (Cv->WaitKey(10) >= 0);
}
