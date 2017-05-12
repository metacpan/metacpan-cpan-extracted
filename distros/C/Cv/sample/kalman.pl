#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

# Tracking of rotating point.  Rotation speed is constant.  Both state
# and measurements vectors are 1D (a point angle), Measurement is the
# real point angle + gaussian noise.  The real and the estimated
# points are connected with yellow line segment, the real and the
# measured points are connected with red line segment.  (if Kalman
# filter works correctly, the yellow segment should be shorter than
# the red one).  Pressing any key (except ESC) will reset the tracking
# with a different speed.  Pressing ESC will stop the program.

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $img = Cv::Image->new([ 500, 500 ], CV_8UC3);
my $kalman = Cv::Kalman->new(2, 1, 0);
my $state = Cv::Mat->new([ 2, 1 ], CV_32FC1);
my $process_noise = Cv::Mat->new([ 2, 1 ], CV_32FC1);
my $measurement = Cv::Mat->new([ 1, 1 ], CV_32FC1);
my $rng = Cv->RNG;
my $code = -1;

$measurement->zero;
Cv->namedWindow("Kalman", 1);

while (1) {
    $rng->randArr($state, CV_RAND_NORMAL, cvRealScalar(0), cvRealScalar(0.1));
	$kalman->transition_matrix
		->setReal([0, 0], 1)->setReal([0, 1], 1)
		->setReal([1, 0], 0)->setReal([1, 1], 1);
	$kalman->measurement_matrix->setIdentity(cvRealScalar(1));
	$kalman->process_noise_cov->setIdentity(cvRealScalar(1e-5));
	$kalman->measurement_noise_cov->setIdentity(cvRealScalar(1e-1));
	$kalman->error_cov_post->SetIdentity(cvRealScalar(1));

	$rng->randArr($kalman->state_post, CV_RAND_NORMAL,
				  cvScalarAll(0), cvScalarAll(0.1));

    while (1) {
		sub calcPoint {
			my ($angle) = @_;
			[ $img->width  / 2 + cos($angle) * $img->width  / 3,
			  $img->height / 2 - sin($angle) * $img->height / 3,
			];
		}

		my $state_pt = &calcPoint($state->getReal(0));
		my $prediction = $kalman->predict(\0);
		my $predict_pt = &calcPoint($prediction->getReal(0));

		$rng->randArr($measurement, CV_RAND_NORMAL, cvRealScalar(0),
			cvRealScalar(sqrt($kalman->measurement_noise_cov->getReal(0))));

		# generate measurement
		$kalman->measurement_matrix
			->matMulAdd($state, $measurement, $measurement);

		my $measurement_pt = &calcPoint($measurement->getReal(0));

		# plot points
		sub drawCross {
			my ($center, $color, $d) = @_;
			my ($x, $y) = @$center;
			$img->line([ $x - $d, $y - $d ],
					   [ $x + $d, $y + $d ], $color, 1, CV_AA, 0);
			$img->line([ $x + $d, $y - $d ],
					   [ $x - $d, $y + $d ], $color, 1, CV_AA, 0);
		}

		$img->zero;
		&drawCross($state_pt, CV_RGB(255, 255, 255), 3);
		&drawCross($measurement_pt, CV_RGB(255, 0, 0), 3);
		&drawCross($predict_pt, CV_RGB(0, 255, 0), 3);
		$img->line($state_pt, $measurement_pt, CV_RGB(255, 0, 0), 3, CV_AA, 0);
		$img->line($state_pt, $predict_pt, CV_RGB(255, 255, 0), 3, CV_AA, 0);

		$kalman->correct($measurement);
		$rng->randArr($process_noise, CV_RAND_NORMAL, cvRealScalar(0),
					  cvRealScalar(sqrt($kalman->process_noise_cov->getReal(0))));
		$kalman->transition_matrix->matMulAdd($state, $process_noise, $state);

		$img->showImage("Kalman");
		$code = Cv->waitKey(100);
		$code &= 0x7f if ($code > 0);
		last if ($code > 0);
	}

	last if ($code == 27 || $code == ord('q') || $code == ord('Q'));
}
