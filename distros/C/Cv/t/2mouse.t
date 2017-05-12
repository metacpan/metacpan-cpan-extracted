# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More qw(no_plan);
# use Test::More tests => 3;
BEGIN { use_ok('Cv', -nomore) }
use Test::Exception;

my $verbose = Cv->hasGUI;

my $win = $0;
my $img = Cv::Image->new([240, 320], CV_8UC3)->zero;
my $remaining0 = 5000;
my $remaining = $remaining0;

my @rects = (
	[  20,  20, 80, 60, &color ],
	[ 120,  20, 80, 60, &color ],
	[ 220,  20, 80, 60, &color ],
	[  20,  90, 80, 60, &color ],
	[ 120,  90, 80, 60, &color ],
	[ 220,  90, 80, 60, &color ],
	[  20, 160, 80, 60, &color ],
	[ 120, 160, 80, 60, &color ],
	[ 220, 160, 80, 60, &color ],
);

sub color { [ map { rand(128) + 127 } 1..3 ] }

my $font = Cv->InitFont(CV_FONT_HERSHEY_SIMPLEX, 0.4, 0.4, 0, 1, CV_AA);

sub onMouse {
	my ($event, $ex, $ey, $flags, $param) = @_;
	# $param ||= 'no param';
	# print STDERR join(', ', $event, $ex, $ey, $flags, $param), "\n";
	foreach (@rects) {
		my ($x, $y, $w, $h, $color) = @$_;
		if ($x <= $ex && $ex < $x + $w && $y <= $ey && $ey < $y + $h) {
			next unless $event;
			if ($event == 1 || $event == 2) {
				$color = [255, 255, 255];
				$remaining = $remaining0;
			}
			$color = [255, 255, 255] if $event == 1 || $event == 2;
			$img->rectangle([$x, $y], [$x + $w, $y + $h], $color, -1);
		}
	}
	$img->showImage($win);
}

SKIP: {
	skip "no window", 1 unless Cv->hasGUI;
	foreach (@rects) {
		my ($x, $y, $w, $h, $color) = @$_;
		$img->rectangle([$x, $y], [$x+$w, $y+$h], $color, -1);
	}
	$img->showImage($win);
	if (10) {
		throws_ok { Cv->setMouseCallback } qr/Usage: Cv::cvSetMouseCallback\(windowName, onMouse= NO_INIT, userdata= NO_INIT\) at $0/;
	}
	Cv->setMouseCallback($win, \&onMouse);
	while ($remaining >= 0) {
		my $text = sprintf("remaining: %.1fs", $remaining / 1000);
		$font->getTextSize($text, my $size, my $baseline);
		my ($x, $y) = (20, 233);
		$img->rectangle(
			[ $x, $y + $baseline ], [ $x + $size->[0], $y - $size->[1] ],
			cvScalarAll(0), -1);
		$img->putText($text, [ $x, $y ], $font, cvScalarAll(255));
		$img->show($win);
		last SKIP if Cv->waitKey(100) >= 0;
		$remaining -= 100;
	}
}


SKIP: {
	skip "no window", 1 unless Cv->hasGUI;
}
