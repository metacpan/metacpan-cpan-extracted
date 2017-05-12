# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 1;		# XXXXX
use Test::Exception;
BEGIN { use_ok('Cv') }

my $verbose = Cv->hasGUI;

my $K = 10;

my ($fx, $fy) = (640, 480);
my ($cx, $cy) = (320, 240);
my $cmat = Cv::Mat->new([], CV_32FC1,
	[ $fx,   0, $cx ],
	[   0, $fy, $cy ],
	[   0,   0,   1 ],
	);
my $dist = Cv::Mat->new([], CV_32FC1,
	[ 0, 0, 0, 0 ],
	);

my $PI = 3.1416;

if (0) {
	my ($x, $y) = (-20, 30);
	foreach my $z (map { $_ * 10 } 1 .. 50) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 0 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 2*$K ],
			);
		my @frames = (
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[-40,  0 + $y, 0 ],
					[-40,  0 + $y, 1000 ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 40,  0 + $y, 0 ],
					[ 40,  0 + $y, 1000 ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 0,  0 + $y,  0 ],
					[ 0,  0 + $y, 80 ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 0,  0 + $y, 200 ],
					[ 0,  0 + $y, 280 ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 0,  0 + $y, 400 ],
					[ 0,  0 + $y, 480 ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 0,  0 + $y, 600 ],
					[ 0,  0 + $y, 680 ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 10 + $x,-10 + $y,  0 + $z ],
					[ 10 + $x, 10 + $y,  0 + $z ],
					[-10 + $x, 10 + $y,  0 + $z ],
					[-10 + $x,-10 + $y,  0 + $z ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 10 + $x,-10 + $y, 40 + $z ],
					[ 10 + $x, 10 + $y, 40 + $z ],
					[-10 + $x, 10 + $y, 40 + $z ],
					[-10 + $x,-10 + $y, 40 + $z ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 10 + $x,-10 + $y,  0 + $z ],
					[ 10 + $x,-10 + $y, 40 + $z ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[ 10 + $x, 10 + $y,  0 + $z ],
					[ 10 + $x, 10 + $y, 40 + $z ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[-10 + $x, 10 + $y,  0 + $z ],
					[-10 + $x, 10 + $y, 40 + $z ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			[ @{
				Cv::Mat->new([], CV_32FC3,
					[-10 + $x,-10 + $y,  0 + $z ],
					[-10 + $x,-10 + $y, 40 + $z ],
					)->ProjectPoints2($rvec, $tvec, $cmat, $dist)
			  } ],
			);
		$img->polyLine(\@frames, -1, cvScalarAll(255));
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}

# exit 0;

if (1.1) {
	foreach (-50 .. 50) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ $PI * $_ / 100, 0, 0 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 2*$K + 1 ],
			);
		$img->circle($_, 2, cvScalarAll(255), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[  $_, -$K, 0 ]} -$K .. +$K),
				   (map {[  $_,   0, 0 ]} -$K .. +$K),
				   (map {[  $_, +$K, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		$img->circle($_, 2, cvScalarAll(127), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[ -$K,  $_, 0 ]} -$K .. +$K),
				   (map {[   0,  $_, 0 ]} -$K .. +$K),
				   (map {[ +$K,  $_, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}

if (1.2) {
	foreach (-50 .. 50) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ 0, $PI * $_ / 100, 0 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 2*$K + 1 ],
			);
		$img->circle($_, 2, cvScalarAll(255), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[  $_, -$K, 0 ]} -$K .. +$K),
				   (map {[  $_,   0, 0 ]} -$K .. +$K),
				   (map {[  $_, +$K, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		$img->circle($_, 2, cvScalarAll(127), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[ -$K,  $_, 0 ]} -$K .. +$K),
				   (map {[   0,  $_, 0 ]} -$K .. +$K),
				   (map {[ +$K,  $_, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}

if (0 * 1.3) {
	foreach (-50 .. 50) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, $PI * $_ / 100 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 2*$K + 1 ],
			);
		$img->circle($_, 2, cvScalarAll(255), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[  $_, -$K, 0 ]} -$K .. +$K),
				   (map {[  $_,   0, 0 ]} -$K .. +$K),
				   (map {[  $_, +$K, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		$img->circle($_, 2, cvScalarAll(127), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[ -$K,  $_, 0 ]} -$K .. +$K),
				   (map {[   0,  $_, 0 ]} -$K .. +$K),
				   (map {[ +$K,  $_, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}

if (0 * 2.1) {
	foreach (-25 .. 25) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 0 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ $_, 0, 2*$K + 50 ],
			);
		$img->circle($_, 2, cvScalarAll(255), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[  $_, -$K, 0 ]} -$K .. +$K),
				   (map {[  $_,   0, 0 ]} -$K .. +$K),
				   (map {[  $_, +$K, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		$img->circle($_, 2, cvScalarAll(127), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[ -$K,  $_, 0 ]} -$K .. +$K),
				   (map {[   0,  $_, 0 ]} -$K .. +$K),
				   (map {[ +$K,  $_, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}

if (0 * 2.2) {
	foreach (-25 .. 25) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 0 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ 0, $_, 2*$K + 50 ],
			);
		$img->circle($_, 2, cvScalarAll(255), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[  $_, -$K, 0 ]} -$K .. +$K),
				   (map {[  $_,   0, 0 ]} -$K .. +$K),
				   (map {[  $_, +$K, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		$img->circle($_, 2, cvScalarAll(127), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[ -$K,  $_, 0 ]} -$K .. +$K),
				   (map {[   0,  $_, 0 ]} -$K .. +$K),
				   (map {[ +$K,  $_, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}

if (0 * 2.3) {
	foreach (-25 .. 25) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 0 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 2*$K + 50 + $_ ],
			);
		$img->circle($_, 2, cvScalarAll(255), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[  $_, -$K, 0 ]} -$K .. +$K),
				   (map {[  $_,   0, 0 ]} -$K .. +$K),
				   (map {[  $_, +$K, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		$img->circle($_, 2, cvScalarAll(127), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[ -$K,  $_, 0 ]} -$K .. +$K),
				   (map {[   0,  $_, 0 ]} -$K .. +$K),
				   (map {[ +$K,  $_, 0 ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}

if (0 * 3) {
	foreach my $z (-25 .. 25) {
		my $img = Cv::Mat->new([$fy, $fx], CV_8UC3)->zero;
		my $rvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 0 ],
			);
		my $tvec = Cv::Mat->new([], CV_32FC1,
			[ 0, 0, 2*$K + 25 ],
			);
		$img->circle($_, 2, cvScalarAll(255), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[  $_, -$K, $z ]} -$K .. +$K),
				   (map {[  $_,   0, $z ]} -$K .. +$K),
				   (map {[  $_, +$K, $z ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		$img->circle($_, 2, cvScalarAll(127), -1) for
			@{ Cv::Mat->new([], CV_32FC3,
				   (map {[ -$K,  $_, $z ]} -$K .. +$K),
				   (map {[   0,  $_, $z ]} -$K .. +$K),
				   (map {[ +$K,  $_, $z ]} -$K .. +$K),
				   )->ProjectPoints2($rvec, $tvec, $cmat, $dist) };
		if ($verbose) {
			$img->show;
			my $key = Cv->waitKey(10);
			$key &= 255 if $key >= 0;
			last if $key == 27 || $key == ord('q');
		}
	}
}
