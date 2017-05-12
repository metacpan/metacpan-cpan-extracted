# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 11;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
#  void cvFlip(const CvArr* src, CvArr* dst=NULL, int flipMode=0)
# ------------------------------------------------------------

my $src = Cv::Mat->new([2, 2], CV_16SC2);
for my $i (0 .. $src->rows - 1) {
	for my $j (0 .. $src->cols - 1) {
		$src->set([$i, $j], [$i, $j]);
	}
}

if (1) {
	my $dst = $src->flip();
	is_deeply($dst->get([0, 0]), $src->get([1, 0]));
	is_deeply($dst->get([0, 1]), $src->get([1, 1]));
}

if (2) {
	my $dst = $src->flip(0);
	is_deeply($dst->get([0, 0]), $src->get([1, 0]));
	is_deeply($dst->get([0, 1]), $src->get([1, 1]));
}

if (3) {
	my $dst = $src->flip(1);
	is_deeply($dst->get([0, 0]), $src->get([0, 1]));
	is_deeply($dst->get([1, 0]), $src->get([1, 1]));
}

if (3) {
	my $dst = $src->flip(-1);
	is_deeply($dst->get([0, 0]), $src->get([1, 1]));
	is_deeply($dst->get([1, 0]), $src->get([0, 1]));
}

if (10) {
	throws_ok { $src->flip(0, 0) } qr/Usage: Cv::Arr::cvFlip\(src, dst=NULL, flipMode=0\) at $0/;
}

if (11) {
	throws_ok { $src->flip($src->new(CV_16SC1)) } qr/OpenCV Error:/;
}
