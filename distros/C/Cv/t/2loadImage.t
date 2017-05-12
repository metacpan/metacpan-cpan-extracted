# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 13;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

use File::Basename;
my $lena = dirname($0) . "/lena.jpg";
my $verbose = Cv->hasGUI;

{
	my $image = Cv->loadImage($lena);
	isa_ok($image, 'Cv::Image');
	if ($verbose) {
		$image->Show($lena);
		Cv->waitKey(500);
	}
}

{
	my $image = cvLoadImage($lena, CV_LOAD_IMAGE_GRAYSCALE);
	isa_ok($image, 'Cv::Image');
	if ($verbose) {
		$image->show($lena);
		Cv->waitKey(500);
	}
}

{
	my $image = Cv::Image->load($lena, CV_LOAD_IMAGE_COLOR);
	isa_ok($image, 'Cv::Image');
	if ($verbose) {
		$image->show($lena);
		Cv->waitKey(500);
	}
}

{
	my $image = Cv->loadImageM($lena, CV_LOAD_IMAGE_COLOR);
	isa_ok($image, 'Cv::Mat');
	if ($verbose) {
		$image->show($lena);
		Cv->waitKey(500);
	}
}

{
	my $image = cvLoadImageM($lena, CV_LOAD_IMAGE_GRAYSCALE);
	isa_ok($image, 'Cv::Mat');
	if ($verbose) {
		$image->show($lena);
		Cv->waitKey(500);
	}
}


{
	my $image = Cv::Mat->load($lena, CV_LOAD_IMAGE_COLOR);
	isa_ok($image, 'Cv::Mat');
	if ($verbose) {
		$image->show($lena);
		Cv->waitKey(1000);
	}
}

{
	throws_ok { Cv->loadImage } qr/Usage: Cv::cvLoadImage\(filename, iscolor=CV_LOAD_IMAGE_COLOR\) at $0/;
}

{
	throws_ok { Cv->loadImageM } qr/Usage: Cv::cvLoadImageM\(filename, iscolor=CV_LOAD_IMAGE_COLOR\) at $0/;
}

{
	my $x;
	lives_ok { $x = Cv->loadImage("path-to-not-exist") };
	is($x, undef);
}

{
	my $x;
	lives_ok { $x = Cv->loadImageM("path-to-not-exist") };
	is($x, undef);
}
