#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Cv::Seq::Point2;
use File::Basename;
use List::Util qw(min);

# This is a standalone program. Pass an image name as a first
# parameter of the program.  Switch between standard and probabilistic
# Hough transform by changing "$HOUGH_STANDARD = 1" to
# "$HOUGH_STANDARD = 0" and back.

my $HOUGH_STANDARD = 0;
if ($0 =~ /(\w+)-(\w+)/) {
	my ($a, $b) = ($1, $2);
	$HOUGH_STANDARD = 0 if ("probabilistic" =~ /^$b/);
	$HOUGH_STANDARD = 1 if ("standard" =~ /^$b/);
}

my $filename = @ARGV > 0? shift : dirname($0).'/'."pic1.png";
my $src = Cv->LoadImage($filename, 0)
    or die "$0: can't loadimage $filename\n";

my $dst = $src->new($src->sizes, CV_8UC1);
my $color_dst = $src->new($src->sizes, CV_8UC3);
my $storage = Cv::MemStorage->new;

$src->Canny(50, 200, 3, $dst);
$dst->CvtColor(CV_GRAY2BGR, $color_dst);

if ($HOUGH_STANDARD) {
    my $lines = $dst->HoughLines2(
		$storage, CV_HOUGH_STANDARD, 1, &CV_PI / 180, 100,
		);
    for (my $i = 0; $i < min($lines->total, 100); $i++) {
        my ($rho, $theta) = unpack("f2", $lines->GetSeqElem($i));
        my ($a, $b) = (cos($theta), sin($theta));
        my ($x0, $y0) = ($a * $rho, $b * $rho);
        my $pt1 = cvPoint($x0 + 1000 * (-$b), $y0 + 1000 * $a);
        my $pt2 = cvPoint($x0 - 1000 * (-$b), $y0 - 1000 * $a);
		$color_dst->Line(
			$pt1, $pt2, CV_RGB(255, 0, 0), 3, CV_AA, 0,
			);
    }
} else {
	my $lines = bless $dst->HoughLines2(
		$storage, CV_HOUGH_PROBABILISTIC, 1, &CV_PI / 180, 50, 50, 10,
		), 'Cv::Seq::Point2';
	$color_dst->Line($_->[0], $_->[1], CV_RGB(255, 0, 0), 3, CV_AA, 0)
		for @$lines;
}

Cv->NamedWindow("Source", 1);
$src->ShowImage("Source");
Cv->NamedWindow("Hough", 1);
$color_dst->ShowImage("Hough");
Cv->WaitKey;
