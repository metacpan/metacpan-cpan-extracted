#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $NUMBER = 100;
my $DELAY = 5;

#my ($width, $height) = (1024, 700);
my ($width, $height) = (320, 240);

# Load the source image
my $image = Cv->CreateImage([$width, $height], 8, 3)->Zero;

# Create a window
my $wndname = "Drawing Demo";
Cv->namedWindow($wndname);
$image->show($wndname);
Cv->waitKey($DELAY);
my $rng = Cv->RNG;

my $line_type = CV_AA; # change it to 8 to see non-antialiased graphics

for (0 .. $NUMBER-1) {
	my $pt1 = [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ];
	my $pt2 = [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ];
	$image->line(
		$pt1, $pt2, &random_color($rng), $rng->randInt % 10, $line_type);
	$image->show($wndname);
	exit if (Cv->waitKey($DELAY) >= 0);
}

for (0 .. $NUMBER-1) {
	my $pt1 = [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ];
	my $pt2 = [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ];
	$image->rectangle(
		$pt1, $pt2, &random_color($rng), $rng->randInt % 10 - 1, $line_type);
	$image->show($wndname);
	exit if (Cv->waitKey($DELAY) >= 0);
}

for (0 .. $NUMBER-1) {
	my $pt1 = [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ];
	my $sz = [ $rng->randInt % 200, $rng->randInt % 200 ];
	my $angle = ($rng->randInt % 1000) * 0.180;
	$image->ellipse(
		$pt1, $sz, $angle, $angle - 100, $angle + 200,
		&random_color($rng), $rng->randInt % 10 - 1, $line_type);
	$image->show($wndname);
	exit if (Cv->WaitKey($DELAY) >= 0);
}

for (0 .. $NUMBER-1) {	
	my @pts = ();
	foreach (0 .. 1) {
		my @pt = ();
		push(@pt, [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ])
			for (0 .. 2);
		push(@pts, \@pt);
	}
	$image->polyLine(
		\@pts, 1, &random_color($rng), $rng->randInt % 10, $line_type);
	$image->showImage($wndname);
	exit if (Cv->waitKey($DELAY) >= 0);
}

for (0 .. $NUMBER-1) {
	my @pts;
	foreach (0 .. 1) {
		my @pt;
		push(@pt, [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ])
			for (0 .. 2);
		push(@pts, \@pt);
	}
	$image->fillPoly(\@pts, &random_color($rng), $line_type);
	$image->show($wndname);
	exit if (Cv->waitKey($DELAY) >= 0);
}

for (0 .. $NUMBER-1) {
	my $pt = [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ];
	$image->circle(
		$pt, $rng->randInt % 300,
		&random_color($rng), $rng->randInt % 10 - 1,
		$line_type
		);
	$image->showImage($wndname);
	exit if (Cv->waitKey($DELAY) >= 0);
}

for (0 .. $NUMBER-1) {
	my $pt = [ map { $rng->randInt % (3 * $_) - $_ } $width, $height ];
	my $font = Cv->InitFont(
		$rng->randInt % 8,
		($rng->randInt % $width) * 0.005 + 0.1,
		($rng->randInt % $width) * 0.005 + 0.1,
		($rng->randInt % 5) * 0.1,
		cvRound($rng->randInt % 10),
		$line_type
		);
	$image->PutText(
		"Testing text rendering!", $pt, $font, &random_color($rng)
		);
	$image->ShowImage($wndname);
	exit if (Cv->WaitKey($DELAY) >= 0);
}

my $scale = $width * 3e-3;
my $thickness = int($width * 5e-3 + 0.5);
my $font = Cv->InitFont(
	CV_FONT_HERSHEY_COMPLEX, $scale, $scale, 0.0, $thickness, $line_type);

$font->getTextSize("OpenCV forever!", my $sz, my $b);
my ($w, $h) = @$sz;

my $pt = [($width - $w) / 2, ($height + $h) / 2];
my $image2 = $image->clone;

for (0 .. 255 - 1) {
	$image2->SubS(cvScalarAll($_), $image);
	$image->PutText("OpenCV forever!", $pt, $font, CV_RGB(255, $_, $_));
	$image->ShowImage($wndname);
	exit if (Cv->WaitKey($DELAY) >= 0);
}

# Wait for a key stroke; the same function arranges events processing
Cv->WaitKey;
exit;

sub random_color {
	my $rng = shift;
    my $icolor = $rng->randInt;
	return CV_RGB($icolor&255, ($icolor>>8)&255, ($icolor>>16)&255);
}

