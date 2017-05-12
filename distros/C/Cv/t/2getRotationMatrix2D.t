# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 20;
use Test::Number::Delta within => 1e-7;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

#  Cv->getRotationMatrix2D($center, $angle, $scale, $map);

if (1) {
	my ($x, $y) = (0, 0);
	my $angle = 45;
	my $scale = 1;
	Cv->getRotationMatrix2D([$x, $y], $angle, $scale, my $map);
	isa_ok($map, "Cv::Mat");
	is($map->rows, 2);
	is($map->cols, 3);
	my $a = $map->getReal([0, 0]);
	my $b = $map->getReal([0, 1]);
	my $rad = CV_PI / 180;
	delta_ok($a, $scale * cos($angle * $rad));
	delta_ok($b, $scale * sin($angle * $rad));
}

if (2) {
	my ($x, $y) = (0, 0);
	my $angle = 45;
	my $scale = 1;
	my $map = Cv->getRotationMatrix2D([$x, $y], $angle, $scale);
	isa_ok($map, "Cv::Mat");
	is($map->rows, 2);
	is($map->cols, 3);
	my $a = $map->getReal([0, 0]);
	my $b = $map->getReal([0, 1]);
	my $rad = CV_PI / 180;
	delta_ok($a, $scale * cos($angle * $rad));
	delta_ok($b, $scale * sin($angle * $rad));
}

if (3) {
	my ($x, $y) = (0, 0);
	my $angle = 45;
	my $scale = 1;
	my $map = Cv->getRotationMatrix2D(
		[$x, $y], $angle, $scale, Cv::Mat->new([2, 3], CV_32FC1)
		);
	isa_ok($map, "Cv::Mat");
	is($map->rows, 2);
	is($map->cols, 3);
	my $a = $map->getReal([0, 0]);
	my $b = $map->getReal([0, 1]);
	my $rad = CV_PI / 180;
	delta_ok($a, $scale * cos($angle * $rad));
	delta_ok($b, $scale * sin($angle * $rad));
}

if (4) {
	my ($x, $y) = (0, 0);
	my $angle = 45;
	my $scale = 1;
	my $map = Cv::Mat->new([2, 3], CV_32FC1);
	Cv->getRotationMatrix2D([$x, $y], $angle, $scale, $map);
	my $a = $map->getReal([0, 0]);
	my $b = $map->getReal([0, 1]);
	my $rad = CV_PI / 180;
	delta_ok($a, $scale * cos($angle * $rad));
	delta_ok($b, $scale * sin($angle * $rad));
}

if (10) {
	throws_ok { Cv->GetRotationMatrix2D } qr/Usage: Cv::cvGetRotationMatrix2D\(center, angle, scale, mapMatrix\) at $0/;
}

if (11) {
	throws_ok { Cv->cvGetRotationMatrix2D(1, 2, 3) } qr/center is not of type CvPoint2D32f in Cv::cv2DRotationMatrix at $0/;
}
