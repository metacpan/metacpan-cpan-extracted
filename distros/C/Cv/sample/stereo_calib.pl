#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

# This is sample from the OpenCV book. The copyright notice is below

# *************** License:**************************
#  Oct. 3, 2008
#  Right to use this code in any way you want without warrenty,
#  support or any guarentee of it working.
#
#  BOOK: It would be nice if you cited it:
#  Learning OpenCV: Computer Vision with the OpenCV Library
#    by Gary Bradski and Adrian Kaehler
#    Published by O'Reilly Media, October 3, 2008
# 
#  AVAILABLE AT: 
#    http://www.amazon.com/Learning-OpenCV-Computer-Vision-Library/dp/0596516134
#    Or: http://oreilly.com/catalog/9780596516130/
#    ISBN-10: 0596516134 or: ISBN-13: 978-0596516130
#
#  OTHER OPENCV SITES:
#  * The source code is on sourceforge at:
#    http://sourceforge.net/projects/opencvlibrary/
#  * The OpenCV wiki page (As of Oct 1, 2008 this is down for
#    changing over servers, but should come back):
#    http://opencvlibrary.sourceforge.net/
#  * An active user group is at:
#    http://tech.groups.yahoo.com/group/OpenCV/
#  * The minutes of weekly OpenCV development meetings are at:
#    http://pr.willowgarage.com/wiki/OpenCV
# ************************************************** */

use strict;
use warnings;
use IO::File;
use File::Basename;
use List::Util qw(max min);
use lib qw(blib/lib blib/arch);
use Cv;

&StereoCalib("stereo_calib.txt", 9, 6, 1);
exit;

# Given a list of chessboard images, the number of corners (nx, ny)
# on the chessboards, and a flag: useCalibrated for calibrated (0) or
# uncalibrated (1: use cvStereoCalibrate(), 2: compute fundamental
# matrix separately) stereo. Calibrate the cameras and display the
# rectified results along with the computed disparity images.

sub StereoCalib {
	my $imageList = shift;
	my $nx = shift;
	my $ny = shift;
	my $useUncalibrated = shift;

	my $displayCorners = 0;
	my $showUndistorted = 1;
	my $isVerticalStereo = 0;		# OpenCV can handle left-right
									# or up-down camera arrangements
	my $maxScale = 1;
	my $squareSize = 1.0;			# Set this to your actual square size

	my $f = new IO::File join('/', dirname($0), $imageList), "r";
	die "can not open file $imageList\n" unless ($f);

	my $n = $nx * $ny;
	my $N = 0;
	my @imageNames = ([ ], [ ]);
	my @points = ([ ], [ ]);
	my @active = ([ ], [ ]);;
    # my $imageSize = [ 0, 0 ];
	my ($w, $h) = (0, 0);

    # ARRAY AND VECTOR STORAGE:
	my $M1 = Cv::Mat->new([3, 3], CV_64F);
	my $M2 = Cv::Mat->new([3, 3], CV_64F);
	my $D1 = Cv::Mat->new([1, 5], CV_64F);
	my $D2 = Cv::Mat->new([1, 5], CV_64F);
	my $R  = Cv::Mat->new([3, 3], CV_64F);
	my $T  = Cv::Mat->new([3, 1], CV_64F);
	my $E  = Cv::Mat->new([3, 3], CV_64F);
	my $F  = Cv::Mat->new([3, 3], CV_64F);

	if ($displayCorners) {
		Cv->NamedWindow("corners", 1);
	}

	# READ IN THE LIST OF CHESSBOARDS:
	my $i = 0;
	while (<$f>) {
		chomp;
		next if (/^\#/);

		my $count = 0;
		my $result = 0;
		my $lr = $i % 2;

		my $filename = join('/', dirname($0), $_);
		my $img = Cv->LoadImage($filename, 0);
		next unless ($img);

        ($w, $h) = @{$img->size};
		push(@{$imageNames[$lr]}, $filename);

		# FIND CHESSBOARDS AND CORNERS THEREIN:
		my @temp = ();
		for (my $s = 1; $s <= $maxScale; $s++) {
			my $timg = $img;
			if ($s != 1) {
                $timg = $img->new([map { $_ * $s } @{$img->size}], $img->type);
                $img->Resize($timg, &CV_INTER_CUBIC);
			}
            $result = $timg->FindChessboardCorners(
				[ $nx, $ny ], \@temp,
				&CV_CALIB_CB_ADAPTIVE_THRESH | &CV_CALIB_CB_NORMALIZE_IMAGE,
				);
			for (my $j = 0; $j < @temp; $j++ ) {
				$temp[$j]->[$_] /= $s for 0..1;
			}
			last if ($result);
		}
		if ($displayCorners) {
			print STDERR "$_\n";
			my $cimg = Cv::Image->new([ $w, $h ], &CV_8UC3);
            $cimg = $img->CvtColor(&CV_GRAY2RGB);
            $cimg->DrawChessboardCorners([$nx, $ny], \@temp, $result);
			Cv->NamedWindow("corners", 0);
            $cimg->ShowImage("corners");

			# Allow ESC to quit
			my $c = Cv->WaitKey(1000);
			$c &= 0x7f if ($c >= 0);
			exit -1 if ($c == 27 || $c == ord('q') || $c == ord('Q') );
        } else {
			print STDERR '.';
		}

		$N = $n*($i - $lr)/2;
		push(@{$active[$lr]}, $result);

		if ($result) {
			# Calibration will suffer without subpixel interpolation
            $img->FindCornerSubPix(
				\@temp, [ 11, 11 ], [ -1, -1 ],
				cvTermCriteria(
					CV_TERMCRIT_ITER | CV_TERMCRIT_EPS,
					30, 0.01),
				);
			foreach my $j (0 .. $#temp) {
				${$points[$lr]}[$N + $j] = [ $temp[$j]->[0], $temp[$j]->[1] ];
			}
		}
		$i++;
	}
	close $f;
	print STDERR "\n";

	# HARVEST CHESSBOARD 3D OBJECT POINT LIST:
	my $nframes = @{$active[0]}; # Number of good chessboads found
    $N = $nframes * $n;

	my $objectPoints = Cv::Mat->new([1, $N], CV_32FC3);
	my $imagePoints1 = Cv::Mat->new([1, $N], CV_32FC2);
	my $imagePoints2 = Cv::Mat->new([1, $N], CV_32FC2);
	my $npoints = Cv::Mat->new([1, $nframes], CV_32S);

	for (my $k = 0; $k < $nframes; $k++) {
		for (my $j = 0; $j < $ny; $j++) {
			for (my $i = 0; $i < $nx; $i++) {
				my $idx = ($k * $ny + $j) * $nx + $i;
				my ($y, $x, $z) = ($j * $squareSize, $i * $squareSize, 0);
				$objectPoints->Set([ 0, $idx ], [ $y, $x, $z ]);
				$imagePoints1->Set([ 0, $idx ], $points[0]->[$idx]);
				$imagePoints2->Set([ 0, $idx ], $points[1]->[$idx]);
			}
		}
		$npoints->Set([ 0, $k ], [ $n ]);
	}

	# CALIBRATE THE STEREO CAMERAS
	print STDERR "Running stereo calibration ...";
	$M1->SetIdentity; $D1->Zero;
	$M2->SetIdentity; $D2->Zero;
    Cv->StereoCalibrate(
		$objectPoints, $imagePoints1, $imagePoints2, $npoints,
		$M1, $D1, $M2, $D2, [ $w, $h ], $R, $T, $E, $F,
		cvTermCriteria(&CV_TERMCRIT_ITER + &CV_TERMCRIT_EPS, 100, 1e-5),
		CV_CALIB_FIX_ASPECT_RATIO + CV_CALIB_ZERO_TANGENT_DIST +
		CV_CALIB_SAME_FOCAL_LENGTH,
		);
	print STDERR " done\n";

	# CALIBRATION QUALITY CHECK
	# because the output fundamental matrix implicitly includes all
	# the output information, we can check the quality of calibration
	# using the epipolar geometry constraint: m2^t*F*m1=0

	# Always work in undistorted space
	$imagePoints1->UndistortPoints($imagePoints1, $M1, $D1, \0, $M1);
	$imagePoints2->UndistortPoints($imagePoints2, $M2, $D2, \0, $M2);

	my $L1 = Cv::Mat->new([1, $N], CV_32FC3);
	my $L2 = Cv::Mat->new([1, $N], CV_32FC3);
    $imagePoints1->ComputeCorrespondEpilines(1, $F, $L1);
    $imagePoints2->ComputeCorrespondEpilines(2, $F, $L2);

	my $avgErr = 0;
	for (my $i = 0; $i < $N; $i++) {
		my $l0 = $L1->Get([ 0, $i ]);
		my $p0 = $imagePoints1->Get([ 0, $i ]);
		my $l1 = $L2->Get([ 0, $i ]);
		my $p1 = $imagePoints2->Get([ 0, $i ]);
		my $err =
			abs($p0->[1] * $l1->[1] + $p0->[0] * $l1->[0] + $l1->[2]) +
			abs($p1->[1] * $l0->[1] + $p1->[0] * $l0->[0] + $l0->[2]);
        $avgErr += $err;
	}
	printf STDERR "avg err = %g\n", $avgErr/($nframes*$n);

	# COMPUTE AND DISPLAY RECTIFICATION
	if ($showUndistorted) {
		my $mx1   = Cv::Mat->new([$h, $w], CV_32F);
		my $my1   = Cv::Mat->new([$h, $w], CV_32F);
		my $mx2   = Cv::Mat->new([$h, $w], CV_32F);
		my $my2   = Cv::Mat->new([$h, $w], CV_32F);
		my $img1r = Cv::Mat->new([$h, $w], CV_8U);
		my $img2r = Cv::Mat->new([$h, $w], CV_8U);
		my $disp  = Cv::Mat->new([$h, $w], CV_16S);
		my $vdisp = Cv::Mat->new([$h, $w], CV_8U);

		my $R1 = Cv::Mat->new([3, 3], CV_64F);
		my $R2 = Cv::Mat->new([3, 3], CV_64F);

		# IF BY CALIBRATED (BOUGUET'S METHOD)
		if ($useUncalibrated == 0) {
			my $P1 = Cv::Mat->new([3, 4], CV_64F);
			my $P2 = Cv::Mat->new([3, 4], CV_64F);

			Cv->StereoRectify(
				$M1, $M2, $D1, $D2, [ $w, $h ],
				$R, $T, $R1, $R2, $P1, $P2, \0,
				0 # CV_CALIB_ZERO_DISPARITY,
				);
			
            $isVerticalStereo =
				abs($P2->GetReal([1, 3]) > $P2->GetReal([0, 3]));

			# Precompute maps for cvRemap()
			printf STDERR "Precompute maps for cvRemap\n";
			Cv->InitUndistortRectifyMap($M1, $D1, $R1, $P1, $mx1, $my1);
			Cv->InitUndistortRectifyMap($M2, $D2, $R2, $P2, $mx2, $my2);

		} elsif ($useUncalibrated == 1 || $useUncalibrated == 2) {

			# OR ELSE HARTLEY'S METHOD
			# use intrinsic parameters of each camera, but compute the
			# rectification transformation directly from the
			# fundamental matrix

			my $H1 = Cv::Mat->new([3, 3], CV_64F);
			my $H2 = Cv::Mat->new([3, 3], CV_64F);
			my $iM = Cv::Mat->new([3, 3], CV_64F);

			# Just to show you could have independently used F
			if ($useUncalibrated == 2) {
				Cv->FindFundamentalMat($imagePoints1, $imagePoints2, $F);
			}
			Cv->StereoRectifyUncalibrated(
				$imagePoints1, $imagePoints2, $F, [ $w, $h ], $H1, $H2, 3);

            $M1->Invert($iM);
            $H1->MatMul($M1, $R1);
            $iM->MatMul($R1, $R1);
            $M2->Invert($iM);
            $H2->MatMul($M2, $R2);
            $iM->MatMul($R2, $R2);

			# Precompute map for cvRemap()
			Cv->InitUndistortRectifyMap($M1, $D1, $R1, $M1, $mx1, $my1);
			Cv->InitUndistortRectifyMap($M2, $D2, $R2, $M2, $mx2, $my2);

        } else {
			die "bad combination of useUncalibrated and useUncalibrated";
		}

		# RECTIFY THE IMAGES AND FIND DISPARITY MAPS
		my $pair;
		unless ($isVerticalStereo) {
            $pair = Cv::Mat->new([$h, $w * 2], CV_8UC3);
		} else {
            $pair = Cv::Mat->new([$h * 2, $w], CV_8UC3);
		}

		# Setup for finding stereo corrrespondences
		my $BMState = Cv::StereoBMState->new;
		die "can\'t CreateStereoBMState" unless $BMState;

        $BMState->preFilterSize(41);
        $BMState->preFilterCap(31);
        $BMState->SADWindowSize(41);
        $BMState->minDisparity(-64);
        $BMState->numberOfDisparities(128);
        $BMState->textureThreshold(10);
        $BMState->uniquenessRatio(15);

		for (my $i = 0; $i < $nframes; $i++ ) {
			my $img1 = Cv->LoadImage(${$imageNames[0]}[$i], 0);
			my $img2 = Cv->LoadImage(${$imageNames[1]}[$i], 0);
			if ($img1 && $img2) {
				$img1->Remap($img1r, $mx1, $my1);
				$img2->Remap($img2r, $mx2, $my2);

				Cv->NamedWindow("img1r", 0);
				Cv->NamedWindow("img2r", 0);
				$img1r->ShowImage("img1r");
				$img2r->ShowImage("img2r");
				Cv->WaitKey(100);

				# $img1r->SaveImage(sprintf("remap_l_%02d.png", $i));
				# $img2r->SaveImage(sprintf("remap_r_%02d.png", $i));

				if (!$isVerticalStereo || $useUncalibrated) {
					# When the stereo camera is oriented vertically,
					# useUncalibrated==0 does not transpose the image,
					# so the epipolar lines in the rectified images
					# are vertical. Stereo correspondence function
					# does not support such a case.
					$BMState->FindStereoCorrespondenceBM($img1r, $img2r, $disp);
					$disp->Normalize($vdisp, 0, 256, CV_MINMAX);
					Cv->NamedWindow("disparity", 0);
					$vdisp->ShowImage("disparity");
				}
				unless ($isVerticalStereo) {
					$img1r->CvtColor(CV_GRAY2BGR, $pair->GetCols(0, $w));
					$img2r->CvtColor(CV_GRAY2BGR, $pair->GetCols($w, $w + $w));
					for (my $j = 0; $j < $h; $j += 16) {
						$pair->Line(
							[ 0, $j ], [ $w * 2, $j ], CV_RGB(0, 255, 0),
							);
					}
				} else {
					$img1r->CvtColor(CV_GRAY2BGR, $pair->GetRows(0, $h));
					$img2r->CvtColor(CV_GRAY2BGR, $pair->GetRows($h, $h + $h));
					for (my $j = 0; $j < $w; $j += 16) {
						$pair->Line(
							[ $j, 0 ], [ $j, $h * 2], CV_RGB(0, 255, 0),
							);
					}
				}
				Cv->NamedWindow("rectified", 0);
				$pair->ShowImage("rectified");
				my $c = Cv->WaitKey;
				$c &= 0x7f if ($c >= 0);
				last if ($c == 27);
			}
		}
	}
}
