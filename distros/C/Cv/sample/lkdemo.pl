#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

package Cv::Arr::OpticalFlowPyrLK;
use Cv;

sub new {
	my $class = shift;
	my $gray = shift;
	bless {
		gray => $gray,
		points => [],
		MAX_COUNT => 500,
		flags => 0,
		win_size => [ 10, 10 ],
		term => Cv::cvTermCriteria(
			CV_TERMCRIT_ITER | CV_TERMCRIT_EPS,
			20, 0.03,
			),
	};
}

sub init {
	my $self = shift;
	my $gray = shift;
	$self->{gray} = $gray;
	my $eigImage = Cv::Image->new($gray->sizes, CV_32FC1);
	my $tempImage = Cv::Image->new($gray->sizes, CV_32FC1);
	Cv::Arr::cvGoodFeaturesToTrack(
		$self->{gray}, $eigImage, $tempImage, $self->{points},
		$self->{MAX_COUNT},
		0.01, 10,
		);
	Cv::Arr::cvFindCornerSubPix(
		$self->{gray}, $self->{points}, $self->{win_size}, [ -1, -1 ],
		$self->{term},
		);
	$self->{points};
}

sub calc {
	my $self = shift;
	my $gray = shift;
	$self->{prev_gray} = $self->{gray};
	$self->{gray} = $gray;
	$self->{prev_pyramid} = $self->{pyramid} || $gray->new;
	$self->{pyramid} = $gray->new;
	$self->{prev_points} = $self->{points};
	$self->{points} = [];
	Cv::Arr::cvCalcOpticalFlowPyrLK(
		$self->{prev_gray}, $self->{gray},
		$self->{prev_pyramid}, $self->{pyramid},
		$self->{prev_points}, $self->{points},
		$self->{win_size}, 3,
		my $status = undef, my $track_error = undef,
		$self->{term},
		$self->{flags},
		);
	$self->{flags} |= CV_LKFLOW_PYR_A_READY;
	$self->{points};
}

sub add {
	my $self = shift;
	if (@{$self->{points}} < $self->{MAX_COUNT}) {
		$self->{gray} = shift;
		my $pt = shift;
		Cv::Arr::cvFindCornerSubPix(
			$self->{gray}, my $p = [ $pt ], $self->{win_size}, [ -1, -1 ],
			$self->{term},
			);
		push(@{$self->{points}}, @{$p});
		return 1;
	}
	0;
}

sub remove {
	my $self = shift;
	if (my $pt = shift) {
		my @good_points = ();
		foreach my $p (@{$self->{points}}) {
			if ($pt) {
				my $dx = $pt->[0] - $p->[0];
				my $dy = $pt->[1] - $p->[1];
				if ($dx*$dx + $dy*$dy <= 25) {
					$pt = undef;
					next;
				}
			}
			push(@good_points, $p);
		}
		$self->{points} = \@good_points;
		return 1 unless $pt;
	}
	0;
}

sub points {
	my $self = shift;
	wantarray ? @{$self->{points}} : $self->{points};
}

package main;

my $image = undef;
my $add_remove_pt = undef;
# my $pt;

sub on_mouse {
	my ($event, $x, $y, $flags, $param) = @_;
    return unless $image;
	$y = $image->height - $y if ($image->origin);
	if ($event == CV_EVENT_LBUTTONDOWN) {
        # $pt = [ $x, $y ];
        $add_remove_pt = [ $x, $y ];
    }
}


my $capture = undef;
if (@ARGV == 0) {
    $capture = Cv::Capture->fromCAM(0);
} elsif (@ARGV == 1 && $ARGV[0] =~ /^\d$/) {
    $capture = Cv::Capture->fromCAM($ARGV[0]);
} else {
    $capture = Cv::Capture->fromFile($ARGV[0]);
}
die "$0: Could not initialize capturing...\n"
	unless $capture;

# print a welcome message, and the OpenCV version
printf("Welcome to lkdemo, using OpenCV version %s (%d.%d.%d)\n",
	   cvVersion, CV_MAJOR_VERSION, CV_MINOR_VERSION, CV_SUBMINOR_VERSION);

print "Hot keys: \n",
	"\tESC - quit the program\n",
	"\tr - auto-initialize tracking\n",
	"\tc - delete all the points\n",
	"\tn - switch the \"night\" mode on/off\n",
	"To add/remove a feature point click it\n";

Cv->NamedWindow("LkDemo");
Cv->SetMouseCallback("LkDemo", \&on_mouse);

my $need_to_init = 0;
my $night_mode = 0;
my $flow;

while (my $frame = $capture->QueryFrame) {

	unless ($image) {
		$image = Cv::Image->new($frame->sizes, CV_8UC3);
	}

	$frame->copy($image);
	my $gray = $image->CvtColor(CV_BGR2GRAY);
	$image->Zero if $night_mode;
	if ($need_to_init) {
		# automatic initialization
		$flow = Cv::Arr::OpticalFlowPyrLK->new;
		$flow->init($gray);
		$need_to_init = 0;
	} elsif ($flow) {
		$flow->calc($gray);
		if ($add_remove_pt) {
			if ($flow->remove($add_remove_pt)) {
				$add_remove_pt = undef;
			}
		}
	} else {
		$flow = undef;
	}
	if ($add_remove_pt) {
		$flow = Cv::Arr::OpticalFlowPyrLK->new unless $flow;
		$flow->add($gray, $add_remove_pt);
		$add_remove_pt = undef;
	}

	if ($flow) {
		$image->Circle($_, 3, CV_RGB(0, 255, 0), -1, 8, 0)
			for $flow->points;
	}
	$image->ShowImage("LkDemo");

	if ((my $c = Cv->WaitKey(10)) >= 0) {
		$c &= 0x7f;
		last if $c == 27 || $c == ord('q');
		$need_to_init = 1 if $c == ord('r');
		$flow = undef if $c == ord('c');
		$night_mode ^= 1 if $c == ord('n');
	}
}
