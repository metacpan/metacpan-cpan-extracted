#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $w = 500;
my $img = Cv::Image->new([$w, $w], CV_8UC1)->Zero;

my $storage = Cv::MemStorage->new;

for (my $i = 0; $i < 6; $i++) {

	my $dx = ($i % 2) * 250 - 30;
	my $dy = Cv->Floor($i / 2) * 150;

	if ($i == 0) {
		for (my $j = 0; $j <= 10; $j++) {
			my $angle = ($j + 5) * CV_PI() / 21;
			$img->Line([ cvRound($dx+100 + $j*10 - 80*cos($angle)),
						 cvRound($dy+100         - 90*sin($angle)) ],
					   [ cvRound($dx+100 + $j*10 - 30*cos($angle)),
						 cvRound($dy+100         - 30*sin($angle)) ],
					   cvScalarAll(255));
		}
	}

	my ($white, $black) = (cvScalarAll(255), cvScalarAll(0));
	for ({ center => [$dx+150, $dy+100], axes => [100, 70], color => $white },
		 { center => [$dx+115, $dy+ 70], axes => [ 30, 20], color => $black },
		 { center => [$dx+185, $dy+ 70], axes => [ 30, 20], color => $black },
		 { center => [$dx+115, $dy+ 70], axes => [ 15, 15], color => $white },
		 { center => [$dx+185, $dy+ 70], axes => [ 15, 15], color => $white },
		 { center => [$dx+115, $dy+ 70], axes => [  5,  5], color => $black },
		 { center => [$dx+185, $dy+ 70], axes => [  5,  5], color => $black },
		 { center => [$dx+150, $dy+100], axes => [ 10,  5], color => $black },
		 { center => [$dx+150, $dy+150], axes => [ 40, 10], color => $black },
		 { center => [$dx+ 27, $dy+100], axes => [ 20, 35], color => $white },
		 { center => [$dx+273, $dy+100], axes => [ 20, 35], color => $white }) {
		$img->ellipse($_->{center}, $_->{axes}, 0, 360, 0, $_->{color}, -1);
	}
}

Cv->namedWindow('image', 1);
$img->showImage('image');

$img->findContours(
	$storage, my $contours, CV_SIZEOF('CvContour'),
	CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

{
    Cv->Save("contours.xml", $contours, \0, \0, [recursive => 1]);
	$contours = Cv->Load("contours.xml", $storage);
}

# comment this out if you do not want approximation
$contours = $contours->approxPoly(
	$contours->header_size, $storage, CV_POLY_APPROX_DP, 3, 1);

Cv->namedWindow('contours', 1);
Cv->createTrackbar('levels+3', 'contours', my $levels = 3, 7, \&on_trackbar);

on_trackbar($levels);
while (1) {
	my $c = Cv->waitKey;
	$c &= 0x7f if ($c >= 0);
	last if $c == 27 || $c == ord('q');
	Cv->setTrackbarPos('levels+3', 'contours', 1) if $c == ord('x');
}
exit 0;

sub on_trackbar {
	my $cnt_img = Cv::Image->new([$w, $w], CV_8UC3)->zero;
    my $_contours = $contours;
	my $_levels = $levels - 3;
    if ($_levels <= 0) { # get to the nearest face to make it look more funny
        $_contours = $_contours->h_next->h_next->h_next;
	}
	$cnt_img->drawContours(
		$_contours, [255, 0, 0], [0, 255, 0], $_levels, 3, CV_AA);
    $cnt_img->showImage('contours');
}
