# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 23;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# my $dst = $src->resize([rows, cols]);

if (1) {
	my $rows = 120;
	my $cols = 160;
	my $src = Cv::Mat->new([$rows*2, $cols*2], CV_8UC3);
	my $dst = $src->resize([$rows, $cols]);
	is(ref $dst, ref $src);
	is($dst->rows, $rows);
	is($dst->cols, $cols);
	is($src->rows, 2 * $rows);
	is($src->cols, 2 * $cols);
}

if (2) {
	my $rows = 120;
	my $cols = 160;
	my $src = Cv::Image->new([$rows*2, $cols*2], CV_8UC3);
	my $dst = $src->resize([$rows, $cols]);
	is(ref $dst, ref $src);
	is($dst->rows, $rows);
	is($dst->cols, $cols);
	is($src->rows, 2 * $rows);
	is($src->cols, 2 * $cols);
}

# my $dst = $src->resize($src->new([rows, cols]));

if (3) {
	my $rows = 120;
	my $cols = 160;
	my $src = Cv::Mat->new([$rows*2, $cols*2], CV_8UC3);
	my $dst = $src->resize($src->new([$rows, $cols]));
	is(ref $dst, ref $src);
	is($dst->rows, $rows);
	is($dst->cols, $cols);
	is($src->rows, 2 * $rows);
	is($src->cols, 2 * $cols);
}

if (4) {
	my $rows = 120;
	my $cols = 160;
	my $src = Cv::Image->new([$rows*2, $cols*2], CV_8UC3);
	my $dst = $src->resize($src->new([$rows, $cols]));
	is(ref $dst, ref $src);
	is($dst->rows, $rows);
	is($dst->cols, $cols);
	is($src->rows, 2 * $rows);
	is($src->cols, 2 * $cols);
}

if (10) {
	my $src = Cv::Mat->new([100, 10], CV_8UC3);
	throws_ok { $src->resize(1, 2, 3) } qr/Usage: Cv::Arr::cvResize\(src, dst, interpolation=CV_INTER_LINEAR\) at $0/;
}

if (11) {
	my $src = Cv::Mat->new([100, 10], CV_8UC3);
	throws_ok { $src->resize(\0) } qr/OpenCV Error:/;
}
