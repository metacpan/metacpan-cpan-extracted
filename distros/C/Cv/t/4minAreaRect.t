# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 3;
use Test::Number::Delta within => 1e-15;
BEGIN { use_ok('Cv') }

sub box_ok {
	my ($got, $exp) = splice(@_, 0, 2);
	my $len = scalar @$exp;
	my $dim = scalar @{$exp->[0]};
	my @delta;
	for my $i (0 .. $len - 1) {
		my $delta = 0;
		for my $j (0 .. $len - 1) {
			$delta += abs($got->[($i + $j) % $len]->[$_] - $exp->[$j]->[$_])
				for 0 .. $dim - 1;
		}
		push(@delta, [$delta, $i]);
	}
	@delta = sort { $a->[0] <=> $b->[0] } @delta;
	if (my $shift = $delta[0]->[1]) {
		my @tmp = splice(@$got, 0, $shift);
		push(@$got, @tmp);
	}
	unshift(@_, $got, $exp);
	goto &Test::Number::Delta::delta_ok;
	# goto &Test::More::is_deeply;
}

my $verbose = Cv->hasGUI;

my $img = Cv::Mat->new([300, 300], CV_8UC3);
my @points = ([ 100, 100 ], [ 200, 100 ], [ 200, 200 ], [ 100, 200 ]);

if (1) {
	my @vtx = Cv->boxPoints(Cv->MinAreaRect(@points));
	box_ok(\@vtx, \@points);
	if ($verbose) {
		$img->zero;
		$img->circle($_, 3, cvScalar(0, 0, 255), CV_FILLED, CV_AA) for @points;
		$img->polyLine([ \@vtx ], 1, cvScalar(0, 255, 0), 1, CV_AA);
		$img->show("rect & circle");
		Cv->waitKey(1000);
	}
}

if (2) {
	my @vtx = Cv->boxPoints(Cv->MinAreaRect(\@points));
	box_ok(\@vtx, \@points);
}
