# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 5;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
#  void cvSubRS(CvArr* src, CvScalar value, CvArr* dst, CvArr* mask=NULL)
# ------------------------------------------------------------

if (1) {
	my $src = Cv::Mat->new([1, 1], CV_32FC4)
		->set([0, 0], [-1, 0, 1, 2]);
	my $dst = $src->subRS([0, 0, 0, 0]);
	is_deeply($dst->get([0, 0]), [1, 0, -1, -2]);
}

if (2) {
	my $src = Cv::Mat->new([1, 2], &CV_32FC4)
		->set([0, 0], [-1, 0, 1, 2])
		->set([0, 1], [-1, 0, 1, 2]);
	my $mask = Cv::Mat->new([1, 2], CV_8UC1)
		->set([0, 0], [0])
		->set([0, 1], [1]);
	my $dst = $src->new->fill([11, 12, 13, 14]);
	$src->subRS([0, 0, 0, 0], $dst, $mask);
	is_deeply($dst->get([0, 0]), [11, 12, 13, 14]);
	is_deeply($dst->get([0, 1]), [ 1,  0, -1, -2]);
}

if (10) {
	my $src = Cv::Mat->new([1, 2], &CV_32FC4);
	throws_ok { $src->subRS } qr/value is not of type CvScalar in Cv::Arr::cvSubRS at $0/;
}
