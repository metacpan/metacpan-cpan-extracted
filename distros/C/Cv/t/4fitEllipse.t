# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 16;
use Test::Number::Delta within => 1e-1;
use Test::Exception;
BEGIN { use_ok('Cv') }
use List::Util qw(sum min max);

my $verbose = Cv->hasGUI;

my $img = Cv::Image->new([240, 320], CV_8UC3);
$img->origin(1);

for (map { [[ 160, 120 ], $_] } 0, 15, 30) {
	my ($center, $angle) = @$_;
	my @points = (
		Cv->boxPoints([ $center, [ 100,  80 ], $angle ]),
		Cv->boxPoints([ $center, [ 140,  60 ], $angle ]),
		);
	$img->zero;
	$img->circle($_, 3, &color, 1, CV_AA) for @points; 
	my $box = aa(Cv->fitEllipse(\@points));
	delta_ok($box->[0], $center);
	delta_ok($box->[2], $angle);
	my @box = Cv->BoxPoints($box);
	$img->polyLine([\@box], -1, &color, 1, CV_AA);
	# $img->EllipseBox($box, &color, 1, CV_AA);
	$img->Ellipse($box->[0], [map { $_ / 2 } @{$box->[1]}], $box->[2],
				  0, 360, &color, 1, CV_AA);
	if ($verbose) {
		$img->show;
		Cv->waitKey(1000);
	}
}

$img->zero;

# Cv-0.16
Cv::More->import(qw(cs));

for (map { [[ 160, 120 ], $_] } 45, 60, 75) {
	my ($center, $angle) = @$_;
	my @points = (
		Cv->boxPoints([ $center, [ 100,  80 ], $angle ]),
		Cv->boxPoints([ $center, [ 140,  60 ], $angle ]),
		);
	$img->zero;
	$img->circle($_, 3, &color, 1, CV_AA) for @points; 
	my $box = aa([Cv->fitEllipse(\@points)]);
	delta_ok($box->[0], $center);
	delta_ok($box->[2], $angle);
	my @box = Cv->BoxPoints($box);
	$img->polyLine([\@box], -1, &color, 1, CV_AA);
	$img->EllipseBox($box, &color, 1, CV_AA);
	if ($verbose) {
		$img->show;
		Cv->waitKey(1000);
	}
}

sub color {
	[ map { (rand 128) + 127 } 1..3 ];
}

sub aa {
	my $box = shift;
	while ($box->[2] >= 90) {
		($box->[1]->[0], $box->[1]->[1]) = ($box->[1]->[1], $box->[1]->[0]);
		$box->[2] -= 90;
	}
	while ($box->[2] < 0) {
		($box->[1]->[0], $box->[1]->[1]) = ($box->[1]->[1], $box->[1]->[0]);
		$box->[2] += 90;
	}
	$box;
}


# Cv-0.19
throws_ok { my @list = Cv->FitEllipse } qr/Usage: Cv::Arr::FitEllipse2\(points\) at $0/;

my $pts3 = [[1, 2], [2, 3], [3, 4]];
my $pts5 = [[1, 2], [2, 3], [3, 4], [5, 6], [7, 8]];

throws_ok { my @list = Cv->FitEllipse($pts3) } qr/OpenCV Error:/;

Cv::More->unimport(qw(cs cs-warn));
Cv::More->import(qw(cs-warn));

{
	no warnings 'redefine';
	local *Carp::carp = \&Carp::croak;
	throws_ok { my @line = Cv->FitEllipse($pts5); } qr/called in list context, but returning scaler at $0/;
}
