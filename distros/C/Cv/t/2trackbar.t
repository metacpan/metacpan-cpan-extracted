# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More qw(no_plan);
# use Test::More tests => 2;
BEGIN { use_ok('Cv', -nomore) }
use Test::Exception;

my $verbose = Cv->hasGUI;
my $window = $0;

if (1) {
	my $image = Cv::Image->new([240, 320], CV_8UC3)->zero;
	if ($verbose) {
		Cv->NamedWindow($window);
		Cv->CreateTrackbar("trackbar1", $window, my $v1 = 0, 255, \&onChange1);
		Cv->CreateTrackbar("trackbar2", $window, my $v2 = 255, 255, \&onChange2);
		$image->ShowImage($window);
		foreach (0 .. 255) {
			Cv->SetTrackbarPos("trackbar1", $window, $_);
			Cv->WaitKey(10);
		}
		Cv->DestroyWindow($window);
		Cv->WaitKey(1000);
	}
}

if (1) {
	my $image = Cv::Image->new([240, 320], CV_8UC3)->zero;
	if ($verbose) {
		Cv->NamedWindow($window);
		Cv->CreateTrackbar("trackbar1", $window, my $v1 = 0, 255, \&onChange1);
		Cv->CreateTrackbar("trackbar2", $window, my $v2 = 255, 255, \&onChange2);
		$image->ShowImage($window);
		foreach (0 .. 255) {
			Cv->SetTrackbarPos("trackbar1", $window, $_);
			Cv->WaitKey(10);
		}
		Cv->DestroyWindow($window);
		Cv->WaitKey(1000);
	}
}

sub onChange1 {
	# print STDERR join(', ', @_), "\n";
	Cv->SetTrackbarPos("trackbar2", $window, 255 - $_[0]);
}

sub onChange2 {
	# print STDERR join(', ', @_), "\n";
	Cv->SetTrackbarPos("trackbar1", $window, 255 - $_[0]);
}
