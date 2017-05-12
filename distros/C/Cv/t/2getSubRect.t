# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 7;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

# ------------------------------------------------------------
# CvMat* cvGetSubRect(const CvArr* arr, CvMat* submat, CvRect *rect)
# ------------------------------------------------------------

if (1) {
	my $src = Cv::Image->new([240, 320], CV_8UC3);

	$src->fill(cvScalarAll(255));
	my $s1 = $src->width * $src->height * 255;
	is($src->sum->[0], $s1);

	if ($verbose) {
		$src->show;
		Cv->waitKey(1000);
	}

	my ($x, $y, $w, $h) = ($src->width/2 - 50, $src->height/2 - 50, 100, 100);
	my $submat = $src->GetSubRect([ $x, $y, $w, $h ]);
	$submat->fill(cvScalarAll(127));
	my $s2 = $submat->width * $submat->height * 127;
	is($submat->sum->[0], $s2);

	if ($verbose) {
		$src->show;
		Cv->waitKey(1000);
	}

	my $s3 = $submat->width * $submat->height * 255;
	is($src->sum->[0], $s1 + $s2 - $s3);

	$submat = undef;
	is($src->sum->[0], $s1 + $s2 - $s3);

	foreach (
		{ rect => [ $x - 80, $y - 60, $w, $h ], color => [ 255, 128, 196 ] },
		{ rect => [ $x + 80, $y - 60, $w, $h ], color => [ 196, 255, 128 ] },
		{ rect => [ $x + 80, $y + 60, $w, $h ], color => [ 255, 196, 128 ] },
		{ rect => [ $x - 80, $y + 60, $w, $h ], color => [ 196, 128, 255 ] },
		) {
		$submat = $src->GetSubRect($_->{rect});
		$submat->fill($_->{color});
	}

	if ($verbose) {
		$src->show;
		Cv->waitKey(1000);
	}

	if (2) {
		my $lut = Cv->createMat(1, 256, CV_8UC1);
		foreach (0 .. 255) {
			$lut->set([0, $_], [ 255 - $_ ]);
		}
		my $dst = $src->new;
		$src->LUT($dst, $lut);

		if ($verbose) {
			$dst->show;
			Cv->waitKey(1000);
		}
	}

	if (3) {
		my $lut = Cv->createMat(1, 256, CV_8UC3);
		foreach (0 .. 255) {
			$lut->set([0, $_], [ map { int rand 256 } 1..3 ]);
		}
		my $dst = $src->new;
		my @srcs = $src->split;
		$srcs[0]->LUT($dst, $lut);
		if ($verbose) {
			$dst->show;
			Cv->waitKey(1000);
		}
	}

	if (4) {
		my $lut = Cv->createMat(256, 1, CV_8UC1);
		foreach (0 .. 255) {
			$lut->set([$_], [ $_ / 2 + 127 ]);
		}
		my $dst = $src->new;
		$src->LUT($dst, $lut);

		if ($verbose) {
			$dst->show;
			Cv->waitKey(1000);
		}
	}

}

if (10) {
	throws_ok { Cv::Arr::cvGetSubRect } qr/Usage: Cv::Arr::cvGetSubRect\(arr, submat, rect\) at $0/;
}

if (11) {
	throws_ok { Cv::Arr::cvGetSubRect(1, 2, 3) } qr/arr is not of type CvArr \* in Cv::Arr::cvGetSubRect at $0/;
}
