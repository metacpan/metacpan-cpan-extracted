#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $ARRAY = 0;					# 1: Cv:Mat, 0: Cv::Seq
$ARRAY = 1 if $0 =~ /-arr/;
$ARRAY = 0 if $0 =~ /-seq/;

Cv->NamedWindow("hull", 1);
my $img = Cv::Image->new([ 500, 500 ], CV_8UC3);
my $storage = Cv::MemStorage->new(0);

while (1) {
	my $count = int(rand(100) + 1);
	my $p;

	if (!$ARRAY) {
        $p = Cv::Seq::Point->new(CV_32SC2, $storage);
	} else {
        $p = Cv::Mat->new([$count, 1], CV_32SC2);
	}

	foreach (0 .. $count - 1) {
		my $pt = [ map { rand($_ / 2) + $_ / 4 } @{$img->size} ];
		if (!$ARRAY) {
			$p->Push($pt);
		} else {
			$p->Set([$_], $pt);
		}
	}

	my $hull;
	if (!$ARRAY) {
		$hull = bless $p->ConvexHull2, "Cv::Seq::Point";
	} else {
		$hull = Cv::Mat->new([ $count, 1 ], CV_32SC1);
        $p->ConvexHull2($hull);
	}

	$img->Zero;
	foreach (0 .. $count - 1) {
		my $pt;
		if (!$ARRAY) {
			$pt = $p->Get($_);
		} else {
			$pt = $p->Get([$_]);
		}
		$img->Circle($pt, 2, CV_RGB(255, 0, 0), CV_FILLED, CV_AA, 0);
	}
	my @pts = map {
		if (!$ARRAY) {
			[ $hull->Get($_) ];
		} else {
			[ @{ $p->Get( [ ${ $hull->Get([$_]) }[0] ] ) }[0..1] ];
		}
	} (0 .. $hull->total - 1);
	$img->polyLine([\@pts], -1, CV_RGB(0, 255, 0), 1, CV_AA, 0);
	$img->ShowImage("hull");

	my $key = Cv->WaitKey(0);
	$key &= 0x7f if $key >= 0;
	last if ($key == 27 || $key == ord('q') || $key == ord('Q')); # 'ESC'
}

exit 0;
