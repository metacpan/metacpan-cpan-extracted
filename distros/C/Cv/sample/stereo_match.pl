#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

#
#  stereo_match.cpp
#  calibration
#
#  Created by Victor  Eruhimov on 1/18/10.
#  Copyright 2010 Argus Corp. All rights reserved.
#

use strict;
use warnings;
use IO::File;
use Time::HiRes qw(gettimeofday);
use lib qw(blib/lib blib/arch);
use Cv;

sub saveXYZ {
	my ($filename, $mat) = @_;
	my $max_z = 1.0e4;
	my $FLT_EPSILON = 1.19209290e-07;
    my $fp = new IO::File "> $filename";
    for (my $y = 0; $y < $mat->rows; $y++) {
        for (my $x = 0; $x < $mat->cols; $x++) {
            my $point = $mat->get([$y, $x]);
            next if abs($point->[2] - $max_z) < $FLT_EPSILON;
			next if abs($point->[2]) > $max_z;
			printf $fp "%f %f %f\n", @{$point}[0..2];
        }
    }
}

my $img1_filename;
my $img2_filename;
my $intrinsic_filename;
my $extrinsic_filename;
my $disparity_filename;
my $point_cloud_filename;

my %alg = (bm => 0, sgbm => 1, hh => 2);
my $alg = $alg{sgbm};
my $SADWindowSize = 0;
my $numberOfDisparities = 0;
my $no_display = 0;
my $scale = 1;
 
sub help {
	die <<"----";
Demo stereo matching converting L and R images into disparity and point clouds
Usage: stereo_match <left-image> <right-image> [--algorithm=bm|sgbm|hh]
  [--block-size=<n>] [--max-disparity=<n>] [--scale=<f>] [--intrinsic=<file>]
  [--extrinsic=<file>] [--no-display] [--output=<file>] [--point-cloud=<file>]
----
}

use Getopt::Long;
&help unless GetOptions(
	"algorithm=s", sub {
		my $i = lc $_[1];
		unless (exists $alg{$i}) {
			die "Command-line parameter error: Unknown stereo algorithm\n";
		}
		$alg = $alg{$i};
	},
	"maxdisparity|max-disparity=i", sub {
		unless ($_[1] >= 1 && $_[1] % 16 == 0) {
			die << "----";
Command-line parameter error: The max disparity (--maxdisparity=<...>) must be
a positive integer divisible by 16
----
;
		}
		$numberOfDisparities = $_[1];
	},
	"blocksize|block-size=i", sub {
		unless ($_[1] >= 1 && $_[1] % 2 == 1) {
			die << "----";
Command-line parameter error: The block size (--blocksize=<...>) must be
a positive odd number
----
;
		}
		$SADWindowSize = $_[1];
	},
	"nodisplay|no-display", \$no_display,
	"scale=s", sub {
		unless ($_[1] >= 0) {
			die << "----";
Command-line parameter error: The scale factor (--scale=<...>) must be
a positive floating-point number
----
;
		}
		$scale = $_[1];
	},
	"intrinsic=s", \$intrinsic_filename,
	"extrinsic=s", \$extrinsic_filename,
	"disparity|output=s", \$disparity_filename,
	"pointcloud|point-cloud=s", \$point_cloud_filename,
	) && @ARGV >= 2;

$img1_filename = shift(@ARGV);
$img2_filename = shift(@ARGV);

if (!$img1_filename || !$img2_filename) {
	warn << "----";
Command-line parameter error: both left and right images must be specified
----
;
	&help;
}

if (!$intrinsic_filename ^ !$extrinsic_filename) {
	warn << "----";
Command-line parameter error: either both intrinsic and extrinsic parameters
must be specified, or none of them (when the stereo pair is already rectified)
----
;
	&help;
}

if (!$extrinsic_filename && $point_cloud_filename) {
	warn << "----";
Command-line parameter error: extrinsic and intrinsic parameters must be
specified to compute the point cloud
----
;
	&help;
}

my $color_mode = $alg == $alg{bm} ? 0 : -1;
my $img1 = Cv->loadImageM($img1_filename, CV_LOAD_IMAGE_COLOR);
my $img2 = Cv->loadImageM($img2_filename, CV_LOAD_IMAGE_COLOR);

unless ($scale == 1) {
	my $method = $scale < 1 ? CV_INTER_AREA : CV_INTER_CUBIC;
	my $sizes = [map { $_ * $scale } @{$img1->sizes}];
	$img1 = $img1->resize($sizes, $method);
	$img2 = $img2->resize($sizes, $method);
}
    
my $roi1;
my $roi2;
my $Q;

if ($intrinsic_filename) {
	my $ifs = Cv->openFileStorage($intrinsic_filename, CV_STORAGE_READ);
	die "Failed to open file $intrinsic_filename\n" unless $ifs;

	my $M1 = $ifs->readByName(\0, "M1");
	my $D1 = $ifs->readByName(\0, "D1");
	my $M2 = $ifs->readByName(\0, "M2");
	my $D2 = $ifs->readByName(\0, "D2");

	my $efs = Cv->openFileStorage($extrinsic_filename, CV_STORAGE_READ);
	die "Failed to open file $extrinsic_filename\n" unless $efs;

	my $R = $efs->readByName(\0, "R");
	my $T = $efs->readByName(\0, "T");

	my $R1 = Cv->createMat(3, 3, CV_64F);
	my $R2 = Cv->createMat(3, 3, CV_64F);
	my $P1 = Cv->createMat(3, 4, CV_64F);
	my $P2 = Cv->createMat(3, 4, CV_64F);
	$Q = Cv->createMat(4, 4, CV_64F);

	my ($rows, $cols) = @{$img1->sizes};
	Cv->StereoRectify(
		$M1, $M2, $D1, $D2, [ $cols, $rows ], $R, $T, $R1, $R2,
		$P1, $P2, $Q,
		CV_CALIB_ZERO_DISPARITY,
		-1, [ $cols, $rows ],
		$roi1, $roi2,
		);

	my $map11 = Cv->createMat($rows, $cols, CV_32F);
	my $map12 = Cv->createMat($rows, $cols, CV_32F);
	Cv->initUndistortRectifyMap($M1, $D1, $R1, $P1, $map11, $map12);
	$img1 = $img1->remap($img1->new, $map11, $map12, CV_INTER_LINEAR);

	my $map21 = Cv->createMat($rows, $cols, CV_32F);
	my $map22 = Cv->createMat($rows, $cols, CV_32F);
	Cv->initUndistortRectifyMap($M2, $D2, $R2, $P2, $map21, $map22);
	$img2 = $img2->remap($img2->new, $map21, $map22, CV_INTER_LINEAR);
}
    
$numberOfDisparities = $numberOfDisparities > 0 ?
	$numberOfDisparities : (($img1->width/8) + 15) & -16;
    
my $disp;
my $t = gettimeofday();
if ($alg == $alg{bm}) {
	my $bm = Cv->createStereoBMState(CV_STEREO_BM_BASIC, $numberOfDisparities);
	$bm->roi1($roi1) if $roi1;
	$bm->roi2($roi2) if $roi2;
	$bm->preFilterCap(31);
	$bm->SADWindowSize($SADWindowSize > 0 ? $SADWindowSize : 9);
	$bm->minDisparity(0);
	$bm->numberOfDisparities($numberOfDisparities);
	$bm->textureThreshold(10);
	$bm->uniquenessRatio(15);
	$bm->speckleWindowSize(100);
	$bm->speckleRange(32);
	$bm->disp12MaxDiff(1);
	$disp = $bm->findStereoCorrespondence(
		$img1->cvtColor(CV_BGR2GRAY),
		$img2->cvtColor(CV_BGR2GRAY),
		$img1->new(CV_16SC1),
		);
} elsif ($alg == $alg{sgbm} || $alg == $alg{hh}) {
	my $sgbm = Cv->createStereoSGBM;
	$sgbm->preFilterCap(63);
	$sgbm->SADWindowSize($SADWindowSize > 0 ? $SADWindowSize : 3);
	my $cn = $img1->channels;
	$sgbm->P1(8 * $cn * $sgbm->SADWindowSize * $sgbm->SADWindowSize);
	$sgbm->P2(32 * $cn * $sgbm->SADWindowSize * $sgbm->SADWindowSize);
	$sgbm->minDisparity(0);
	$sgbm->numberOfDisparities($numberOfDisparities);
	$sgbm->uniquenessRatio(10);
	$sgbm->speckleWindowSize(100);
	$sgbm->speckleRange(32);
	$sgbm->disp12MaxDiff(1);
	$sgbm->fullDP($alg == $alg{hh});
	$disp = $sgbm->findStereoCorrespondence(
		$img1, $img2, $img1->new(CV_16SC1),
		);
}
$t = gettimeofday() - $t;
printf("Time elapsed: %.3fs\n", $t);

my $disp8 = $disp->convertScale(
	$disp->new(CV_8U), 255/($numberOfDisparities*16)
	);

unless ($no_display) {
	Cv->namedWindow("left", 0);
	$img1->show("left");
	Cv->namedWindow("right", 0);
	$img2->show("right");
	Cv->namedWindow("disparity", 0);
	$disp8->show("disparity");
	print STDERR "press any key to continue...";
	Cv->waitKey();
	print STDERR "\n";
}

if ($disparity_filename) {
	$disp8->save($disparity_filename);
}

if ($point_cloud_filename) {
	printf("storing the point cloud...");
	select((select(STDOUT), $| = 1)[0]);
	my $xyz = $disp->new(CV_32FC3);
	$disp->reprojectImageTo3D($xyz, $Q, 1);
	saveXYZ($point_cloud_filename, $xyz);
	printf("\n");
}
