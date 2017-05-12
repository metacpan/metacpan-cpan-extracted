# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

if (1) {
	my $mat = Cv::Mat->new([3, 1], CV_8UC1);
	$mat->Set([$_ - ord('A')], cvScalar($_)) for ord('A') .. ord('C');
	is($mat->Ptr, "ABC");
	my $s = $mat->Ptr(1);
	is(length($s), 2);
}

if (2) {
	my $mat = Cv::Mat->new([1, 3], CV_8UC1);
	$mat->Set([0, $_ - ord('A')], cvScalar($_)) for ord('A') .. ord('C');
	is($mat->Ptr, "ABC");
	my $s = $mat->Ptr(0, 1);
	is(length($s), 2);
}

if (3) {
	my $mat = Cv::MatND->new([1, 1, 3], CV_8UC1);
	$mat->Set([0, 0, $_ - ord('A')], cvScalar($_)) for ord('A') .. ord('C');
	is($mat->Ptr, "ABC");
	my $s = $mat->Ptr(0, 0, 1);
	is(length($s), 2);
}

if (4) {
	my $mat = Cv::MatND->new([1, 1, 3, 1], CV_8UC1);
	$mat->Set([0, 0, $_ - ord('A')], cvScalar($_)) for ord('A') .. ord('C');
	is($mat->Ptr, "ABC");
	my $s = $mat->Ptr(0, 0, 1);
	is(length($s), 2);
}

if (5) {
	my $mat = Cv::Mat->new([3, 1], CV_8UC1);
	$mat->Set([$_ - ord('A')], cvScalar($_)) for ord('A') .. ord('C');
	is($mat->Ptr, "ABC");
	my $s = $mat->Ptr([1]);
	is(length($s), 2);
}

if (11) {
	my $mat = Cv::Mat->new([3, 1], CV_8UC1);
	throws_ok { $mat->Ptr({}) } qr/OpenCV Error:/;
}
