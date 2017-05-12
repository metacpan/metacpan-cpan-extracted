# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 7;
use Test::Exception;
use version;
BEGIN { use_ok('Cv', -nomore) }

#  cvMatchTemplate(image, templ, [result], method)
#  (1) $image->MatchTemplate($templ, CV_TM_SQDIFF);
#  (2) $image->MatchTemplate($templ, $result, CV_TM_SQDIFF);

my $R = 45;

if (1) {
	my $image = Cv::Mat->new([240, 320], CV_8UC1)->zero;
	my $templ = Cv::Mat->new([2 * $R, 2 * $R], CV_8UC1)->zero;
	$templ->circle([$R, $R ], $R, cvScalarAll(255), 1, CV_AA);
	my @sz = ($image->cols - $templ->cols, $image->rows - $templ->rows);
	my @pt = ( map { int rand $_ } @sz );
	$templ->copy($image->getSubRect([ @pt, @{$templ->size} ]));
	my $result = $image->matchTemplate($templ, CV_TM_SQDIFF);
	is_deeply($result->size, [ map { $_ + 1 } @sz ]);
	is($result->type, CV_32FC1);
	$result->minMaxLoc(my $minVal, my $maxVal, my $minLoc, my $maxLoc);
	my @minLocErr = map { $minLoc->[$_] - $pt[$_] } 0..1;
	my @maxLocErr = map { $maxLoc->[$_] - $pt[$_] } 0..1;
	unless (abs($minLocErr[0]) <= 1.1 && abs($minLocErr[1]) <= 1.1 ||
			abs($maxLocErr[0]) <= 1.1 && abs($maxLocErr[1]) <= 1.1) {
		diag(sprintf("minLoc: %dx%d, maxLoc", @minLocErr, @maxLocErr));
	}
}

if (2) {
	my $image = Cv::Mat->new([240, 320], CV_8UC1)->zero;
	my $templ = Cv::Mat->new([2 * $R, 2 * $R], CV_8UC1)->zero;
	my $result = Cv->CreateMat($image->rows - $templ->rows + 1,
							   $image->cols - $templ->cols + 1,
							   CV_32FC1);
	my $dst = $image->matchTemplate($templ, $result, CV_TM_SQDIFF);
	is($dst, $result);
}

if (10) {
	my $image = Cv::Mat->new([240, 320], CV_8UC1)->zero;
	throws_ok { $image->matchTemplate; } qr/Usage: Cv::Arr::cvMatchTemplate\(image, templ, result, method\) at $0/;
}

if (11) {
	my $image = Cv::Mat->new([240, 320], CV_8UC1)->zero;
	my $templ = Cv::Mat->new([480, 640], CV_8UC1)->zero;
	throws_ok { $image->matchTemplate($templ); } qr/OpenCV Error:/;
}

if (12) {
	my $image = Cv::Mat->new([240, 320], CV_8UC1)->zero;
	my $templ = Cv::Mat->new([24 + 1, 32 + 1], CV_8UC1)->zero;
	throws_ok { $image->matchTemplate($templ, -1); } qr/OpenCV Error:/;
}
