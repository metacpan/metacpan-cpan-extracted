#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use List::Util qw(max min);

my $cap;
if (@ARGV == 0) {
    $cap = Cv::Capture->fromCAM(0);
} elsif (@ARGV == 1 && $ARGV[0] =~ /^\d$/) {
    $cap = Cv::Capture->fromCAM($ARGV[0]);
} else {
    $cap = Cv::Capture->fromFile($ARGV[0]);
}
$cap or die "can't create capture";

print "Hot keys: \n",
	"\tESC - quit the program\n",
	"\tc - stop the tracking\n",
	"\tb - switch to/from backprojection view\n",
	"\th - show/hide object histogram\n",
	"To initialize tracking, select the object with mouse\n";

my ($vmin, $vmax, $smin) = (10, 256, 30);
my $image = $cap->QueryFrame->Clone;
Cv->NamedWindow("CamShiftDemo");
Cv->SetMouseCallback("CamShiftDemo", \&on_mouse);
Cv->CreateTrackbar("Vmin", "CamShiftDemo", $vmin, 256);
Cv->CreateTrackbar("Vmax", "CamShiftDemo", $vmax, 256);
Cv->CreateTrackbar("Smin", "CamShiftDemo", $smin, 256);

my $histimg = Cv::Image->new([200, 320], CV_8UC3)->Zero;
my $hdims = 16;
my $hranges_arr = [0, 180];
my $hist = Cv::Histogram->new([$hdims], CV_HIST_ARRAY, [$hranges_arr]);

my $selection;
my $origin;
my $select_object;
my $track_object;
my $track_window;

my $backproject_mode = 0;
my $show_hist = 1;

while (1) {
	$image = $cap->QueryFrame->Clone;
	my $hsv = $image->CvtColor(CV_BGR2HSV);
	
	if ($track_object) {
		my $mask = Cv::Image->new($image->sizes, CV_8UC1);
		$hsv->InRange([0, $smin, min($vmin, $vmax), 0],
					  [180, 256, max($vmin, $vmax), 0],
					  $mask);
		my ($hue) = $hsv->Split;
		if ($track_object < 0) {
			$hue->SetROI($selection);
			$mask->SetROI($selection);
			$hist->Calc([$hue], $mask);
			$hue->ResetROI;
			$mask->ResetROI;
			$track_window = $selection;
			$track_object = 1;

			my $bin_w = $histimg->width / $hdims;
			for my $i (0 .. $hdims - 1) {
				my $val = cvRound($hist->QueryHistValue([$i]) *
								  $histimg->height / 255);
				my $color = hsv2rgb($i * 180 / $hdims);
				$histimg->Rectangle(
					[$i * $bin_w, $histimg->height],
					[($i + 1) * $bin_w, $histimg->height - $val],
					$color, -1, 8, 0);
			}
		}
		 
		$hist->CalcBackProject([$hue], my $backproject = $hue->new);
		$backproject->And($mask, $backproject)
			->CamShift($track_window,
					   cvTermCriteria(CV_TERMCRIT_EPS|CV_TERMCRIT_ITER, 10, 1),
					   my $comp, my $box);
		$track_window = $comp->[2]; # rect
		$image = $backproject->CvtColor(CV_GRAY2BGR) if($backproject_mode);
		# $box->[2] = -$box->[2] if $image->origin == 0; # angle
		$image->EllipseBox($box, CV_RGB(255, 0, 0), 3);
	}

	if ($select_object && $selection->[2] > 0 && $selection->[3] > 0) {
		$image->SetROI($selection);
		$image->Xor([255, 255, 255], $image);
		$image->ResetROI;
	}

	$image->ShowImage("CamShiftDemo");
	$histimg->ShowImage("Histogram") if ($show_hist);

	my $c = Cv->WaitKey(30);
	$c &= 0x7f if ($c > 0);
	if ($c == 27) {
		last;
	} elsif (chr($c) eq 'b') {
		$backproject_mode ^= 1;
	} elsif (chr($c) eq 'c') {
		$track_object = 0;
		$histimg->Zero;
	} elsif (chr($c) eq 'h') {
		$show_hist ^= 1;
		Cv->DestroyWindow("Histogram") unless ($show_hist);
	}
}

exit;

sub hsv2rgb {
	my $hue = shift;
    my @sector_data = ( [0,2,1], [1,2,0], [1,0,2],
						[2,0,1], [2,1,0], [0,1,2] );
    $hue *= 0.033333333333333333333333333333333;
    my $sector = Cv->Floor($hue);
    my $p = cvRound(255*($hue - $sector));
    $p ^= $sector & 1 ? 255 : 0;
	
    my @rgb;
    $rgb[$sector_data[$sector][0]] = 255;
    $rgb[$sector_data[$sector][1]] = 0;
    $rgb[$sector_data[$sector][2]] = $p;
	
    return [$rgb[2], $rgb[1], $rgb[0]];
}


sub on_mouse {
	my ($event, $x, $y, $flags, $param) = @_;

	return unless $image;
	unless ($image->origin == 0) {
		$y = $image->height - $y;
	}

	if ($select_object) {
		my $sx = min($x, $origin->[0]);
		my $sy = min($y, $origin->[1]);
		my $sw = $sx + abs($x - $origin->[0]);
		my $sh = $sy + abs($y - $origin->[1]);
        $selection = [
			max($sx, 0),
			max($sy, 0),
			min($sw, $image->width) - $sx,
			min($sh, $image->height) - $sy,
			];
	}

	if ($event == CV_EVENT_LBUTTONDOWN) {
		$origin = [ $x, $y ];
		$selection = [ $x, $y, 0, 0 ];
		$select_object = 1;
	} elsif ($event == CV_EVENT_LBUTTONUP) {
		$select_object = 0;
		if ($selection->[2] > 0 && $selection->[3] > 0) {
			$track_object = -1;
		}
	} elsif ($event == CV_EVENT_RBUTTONDOWN) {
		$select_object = 0;
		$track_object = 0;
	}
}
