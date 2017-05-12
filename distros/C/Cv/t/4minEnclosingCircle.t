# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok('Cv') }

sub xy {
	my @xy = map { ref $_ ? @$_ : $_ } @_;
	sprintf("(%g, %g)", map { int(($_ + 0.5e-7)*1e7)*1e-7 } @xy);
}

my $verbose = Cv->hasGUI;

my $img = Cv::Mat->new([300, 300], CV_8UC3);
my @points = ( [ 100, 100 ], [ 200, 100 ],
			   [ 100, 200 ], [ 200, 200 ] );

if (1) {
	my $center_radius = Cv->minEnclosingCircle(@points);
	my ($center, $radius) = @$center_radius;
	is(xy($center), xy([150, 150]));
	ok(abs($radius - 50*sqrt(2)) < 3);
	# print STDERR abs($radius - 50*sqrt(2)), "\n";

	if ($verbose) {
		$img->zero;
		$img->circle($_, 3, cvScalar(0, 0, 255), CV_FILLED, CV_AA) for @points;
		$img->circle($center, $radius, cvScalar(0, 255, 255), 1, CV_AA); 
		$img->show("rect & circle");
		Cv->waitKey(1000);
	}
}

if (2) {
	my $center_radius = Cv->minEnclosingCircle([@points]);
	is(xy($center_radius->[0]), xy([150, 150]));
	ok(abs($center_radius->[1] - 50*sqrt(2)) < 3);
}


# Cv-0.16
if (11) {
	Cv->minEnclosingCircle(@points, my $center, my $radius);
	is(xy($center), xy([150, 150]));
	ok(abs($radius - 50*sqrt(2)) < 3);
}

if (12) {
	Cv->minEnclosingCircle(\@points, my $center, my $radius);
	is(xy($center), xy([150, 150]));
	ok(abs($radius - 50*sqrt(2)) < 3);
}


# Cv-0.19
if (21) {
	Cv::More->unimport(qw(cs cs-warn));
	Cv::More->import(qw(cs-warn));
	no warnings 'redefine';
	local *Carp::carp = \&Carp::croak;
	throws_ok { my @line = Cv->minEnclosingCircle(\@points); } qr/called in list context, but returning scaler at $0/;
}

if (22) {
	Cv::More->unimport(qw(cs cs-warn));
	Cv::More->import(qw(cs));
	no warnings 'redefine';
	local *Carp::carp = \&Carp::croak;
	lives_ok { my @line = Cv->minEnclosingCircle(\@points); is(@line, 2); };
}
