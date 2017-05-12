# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 2;
use Test::Exception;
BEGIN { use_ok('Cv') }

my $verbose = Cv->hasGUI;

my $img = Cv::Image->new([240, 320], CV_8UC3);
$img->origin(1);

if (1) {
	my @points;
	my $a = $img->height / $img->width;
	foreach (1 .. 100) {
		my $b = ((rand 0.2) - 0.10) * $img->height;
		my $x = ((rand 0.5) + 0.25) * $img->width;
		my $y = $a * $x + $b;
		push(@points, [$x, $y]);
	}
	$img->circle($_, 3, &color, 1, CV_AA) for @points; 
	my $rect = Cv->boundingRect(\@points);
	my ($x, $y, $w, $h) = @$rect;
	my $box = [ [ $x + $w / 2, $y + $h / 2 ], [ $w, $h ], 0 ];
	my @b4 = Cv->BoxPoints($box);
	$img->polyLine([\@b4], -1, &color, 1, CV_AA);
	$img->EllipseBox($box, &color, 1, CV_AA);
	if ($verbose) {
		$img->show;
		Cv->waitKey(1000);
	}
}

$img->zero;

# Cv-0.16
Cv::More->import(qw(cs));

if (2) {
	my $points = Cv::Seq::Point->new(CV_32FC2);
	my $a = $img->height / $img->width;
	foreach (1 .. 100) {
		my $b = ((rand 0.2) - 0.10) * $img->height;
		my $x = ((rand 0.5) + 0.25) * $img->width;
		my $y = $a * $x + $b;
		$points->push([$x, $y]);
	}
	$img->circle($_, 3, &color, 1, CV_AA) for $points->toArray; 
	my $rect = [$points->boundingRect];
	my ($x, $y, $w, $h) = @$rect;
	my $box = [ [ $x + $w / 2, $y + $h / 2 ], [ $w, $h ], 0 ];
	my @b4 = Cv->BoxPoints($box);
	$img->polyLine([\@b4], -1, &color, 1, CV_AA);
	$img->EllipseBox($box, &color, 1, CV_AA);
	if ($verbose) {
		$img->show;
		Cv->waitKey(1000);
	}
}

sub color {
	[ map { (rand 128) + 127 } 1..3 ];
}


# Cv-0.19

Cv::More->unimport(qw(cs));
Cv::More->import(qw(cs-warn));

if (11) {
	no warnings 'redefine';
	local *Carp::carp = \&Carp::croak; # capturing carp as croak
	throws_ok { my @retval = Cv->boundingRect([10, 20], [10, 30]) } qr/called in list context, but returning scaler at $0/;
}
