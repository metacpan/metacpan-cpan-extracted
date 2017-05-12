# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 25;
use Test::Exception;
BEGIN { use_ok('Cv') }

if (1) {
	my $points = Cv::Mat->new([3, 1], CV_32FC2);
	$points->set([0], [1, 1]);
	$points->set([1], [2, 2]);
	$points->set([2], [3, 3]);
	$points->FitLine(CV_DIST_L2, 0, 0.01, 0.01, my $line);
	my ($vx, $vy, $x0, $y0) = @$line;
	cmp_ok(abs(1 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1e-6);
}

if (2) {
	my $points = Cv::Mat->new([3, 1], CV_32FC2);
	$points->set([0], [1, 1]);
	$points->set([1], [2, 2]);
	$points->set([2], [3, 3]);
	$points->FitLine(CV_DIST_L2, 0, 0.01, 0.01, \my @line);
	my ($vx, $vy, $x0, $y0) = @line;
	cmp_ok(abs(1 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1e-6);
}

if (3) {
	Cv->FitLine([[1, 2], [2, 3], [3, 4]], CV_DIST_L2, 0, 0.01, 0.01, \my @line);
	my ($vx, $vy, $x0, $y0) = @line;
	cmp_ok(abs(1 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1 + 1e-6);
}

if (4) {
	Cv->FitLine([[1, 2, 1], [2, 3, 1.5], [3, 4, 2]], CV_DIST_L2, my $line);
	my ($vx, $vy, $vz, $x0, $y0, $z0) = @$line;
	cmp_ok(abs(1.0 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs(0.5 - ($vz / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1 + 1e-6);
	cmp_ok(abs($z0 - ($vz / $vx) * $x0), '<', 1 + 1e-6);
}


# Cv-0.16
Cv::More->import(qw(cs));

if (11) {
	my $points = Cv::Mat->new([3, 1], CV_32FC2);
	$points->set([0], [1, 1]);
	$points->set([1], [2, 2]);
	$points->set([2], [3, 3]);
	my $line = $points->FitLine(CV_DIST_L2, 0, 0.01, 0.01);
	my ($vx, $vy, $x0, $y0) = @$line;
	cmp_ok(abs(1 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1e-6);
}

if (12) {
	my $points = Cv::Mat->new([3, 1], CV_32FC2);
	$points->set([0], [1, 1]);
	$points->set([1], [2, 2]);
	$points->set([2], [3, 3]);
	my @line = $points->FitLine(CV_DIST_L2, 0, 0.01, 0.01);
	my ($vx, $vy, $x0, $y0) = @line;
	cmp_ok(abs(1 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1e-6);
}

if (13) {
	my @line = Cv->FitLine([[1, 2], [2, 3], [3, 4]], CV_DIST_L2, 0, 0.01, 0.01);
	my ($vx, $vy, $x0, $y0) = @line;
	cmp_ok(abs(1 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1 + 1e-6);
}

if (14) {
	my $line = Cv->FitLine([[1, 2, 1], [2, 3, 1.5], [3, 4, 2]], CV_DIST_L2);
	my ($vx, $vy, $vz, $x0, $y0, $z0) = @$line;
	cmp_ok(abs(1.0 - ($vy / $vx)), '<', 1e-6);
	cmp_ok(abs(0.5 - ($vz / $vx)), '<', 1e-6);
	cmp_ok(abs($y0 - ($vy / $vx) * $x0), '<', 1 + 1e-6);
	cmp_ok(abs($z0 - ($vz / $vx) * $x0), '<', 1 + 1e-6);
}


# Cv-0.19
throws_ok { my @line = Cv->FitLine } qr/Usage: Cv::Arr::FitLine\(points, distType=CV_DIST_L2, param=0, reps=0\.01, aeps=0\.01\) at $0/;

throws_ok { my @line = Cv->FitLine([]) } qr/points is not \[ pt1, pt2, \.\.\. \] in Cv::Arr::FitLine at $0/;

throws_ok { my @line = Cv->FitLine([[1, 2], [2, 3], [3, 4]], -1) } qr/OpenCV Error:/;

Cv::More->unimport(qw(cs cs-warn));
Cv::More->import(qw(cs-warn));
{
	no warnings 'redefine';
	local *Carp::carp = \&Carp::croak;
	throws_ok { my @line = Cv->FitLine([[1, 2], [2, 3], [3, 4]]) } qr/called in list context, but returning scaler at $0/;
}
