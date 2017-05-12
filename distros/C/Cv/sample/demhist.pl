#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;
use List::Util qw(max min);

# Load the source image. HighGUI use.
my $file_name = @ARGV > 0 ? shift : dirname($0).'/'."baboon.jpg";
my $src_image = Cv->LoadImage($file_name, CV_LOAD_IMAGE_GRAYSCALE) or 
    die "Image was not loaded.\n";

my $hist_size = 64;
my $ranges = [ [0, 256] ];
my $hist = Cv::Histogram->new([$hist_size], CV_HIST_ARRAY, $ranges);
my $lut = Cv::Mat->new([1, 256], CV_8UC1);

my $brightness = 100;
my $contrast = 100;
Cv->NamedWindow("image");
Cv->CreateTrackbar("brightness", "image", $brightness, 200, \&update_brightcont);
Cv->CreateTrackbar("contrast", "image", $contrast, 200, \&update_brightcont);
Cv->NamedWindow("histogram");

&update_brightcont;
Cv->WaitKey;

# brightness/contrast callback function
sub update_brightcont {
	my $brightness = $brightness - 100;
	my $contrast = $contrast - 100;

	# The algorithm is by Werner D. Streidt
	# (http://visca.com/ffactory/archives/5-99/msg00021.html)
	my ($a, $b);
	if ($contrast > 0) {
		my $delta = 127 * $contrast / 100;
		$a = 255 / (255 - $delta*2);
		$b = $a * ($brightness - $delta);
	} else {
		my $delta = -128 * $contrast / 100;
		$a = (256 - $delta*2) / 255.;
		$b = $a * $brightness + $delta;
	}
	$lut->set([0, $_], [ min(max(0, cvRound($a * $_ + $b)), 255) ])
		for (0 .. 255);
	my $dst_image = $src_image->LUT($lut);
	$dst_image->ShowImage("image");

	my $hist_image = Cv::Image->new([200, 320], CV_8UC1);
	$hist->CalcHist([$dst_image]);
	$dst_image->Zero;
	$hist->GetMinMaxHistValue(
		my $min_val, my $max_val, my $min_idx, my $max_idx,
		);
	if ($max_val) {
		my $bins = $hist->bins;
		$bins->ConvertScale($bins, $hist_image->height / $max_val, 0);
	}
	# $hist->NormalizeHist(1000);
	my ($black, $white) = (cvScalarAll(0), cvScalarAll(255));
	$hist_image->fill($white);
	my $bin_w = cvRound($hist_image->width / $hist_size);
	for (0 .. $hist_size - 1) {
		my ($x, $y) = ($_ * $bin_w, $hist_image->height);
		my $pt1 = [$x, $y];
		my $pt2 = [$x + $bin_w, $y - cvRound($hist->QueryHistValue($_))];
		$hist_image->Rectangle($pt1, $pt2, $black, -1, 8, 0);
	}
	$hist_image->ShowImage("histogram");
}
