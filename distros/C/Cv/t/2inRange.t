# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 13;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;
my $win = $0;

if ($verbose) {
	Cv->NamedWindow($win);
}

my $image = &makeImage($win);
my $inrange;

sub sumInrange {
	${$inrange->Sum}[0] / 255;
}

my ($lower, $upper) = (0, 255);

if ($verbose) {
	Cv->CreateTrackbar("Lower", $win, $lower, 255, \&refresh);
	Cv->CreateTrackbar("Upper", $win, $upper, 255, \&refresh);
}

sub refresh {
	$inrange = 
		$image->cvtColor(CV_RGB2GRAY)->inRange(
			cvScalar($lower), cvScalar($upper),
			# $image->new(CV_8UC1),
		);
	my $src2 = Cv->merge([$inrange, $inrange, $inrange]);
	my $dst = $image->and($src2);
	if ($verbose) {
		$dst->show($0);
	}
}

&refresh;

foreach (
	# { Lower =>   0, Upper => 255, Sum => 76800 },
	{ Lower =>   0, Upper => 254, Sum => 46800 },
	{ Lower => 129, Upper => 254, Sum => 40000 },
	{ Lower => 129, Upper => 222, Sum => 30000 },
	{ Lower => 129, Upper => 205, Sum => 20000 },
	{ Lower => 129, Upper => 173, Sum => 10000 },
	{ Lower => 129, Upper => 162, Sum =>     0 },
	) {
	if ($verbose) {
		Cv->setTrackbarPos("Upper", $win, $_->{Upper});
		Cv->setTrackbarPos("Lower", $win, $_->{Lower});
		Cv->waitKey(1000);
	} else {
		$lower = $_->{Lower};
		$upper = $_->{Upper};
		&refresh;
	}
	is(&sumInrange, $_->{Sum});
}

if (10) {
	my $src = Cv::Mat->new([240, 320], CV_8UC1);
	my $lower = Cv::Mat->new([240, 320], CV_8UC2);
	my $upper = Cv::Mat->new([240, 320], CV_8UC2);
	throws_ok { $src->inRange($lower, $upper) } qr/OpenCV Error:/;
}

if (11) {
	my $src = Cv::Mat->new([240, 320], CV_32FC1);
	my $lower = Cv::Mat->new([240, 320], CV_32FC1);
	my $upper = Cv::Mat->new([240, 320], CV_32FC1);
	lives_ok { $src->inRange($lower, $upper) };
}

sub makeImage {
	my $win = shift;
	my $src = Cv::Image->new([240, 320], CV_8UC3);
	$src->fill(cvScalarAll(255));
	my $s1 = $src->width * $src->height * 255;
	is($src->sum->[0], $s1);

	if ($verbose) {
		$src->show($win);
		Cv->waitKey(100);
	}

	my ($x, $y, $w, $h) = ($src->width/2 - 50, $src->height/2 - 50, 100, 100);
	my $submat = $src->GetSubRect([ $x, $y, $w, $h ]);
	$submat->fill(cvScalarAll(127));
	my $s2 = $submat->width * $submat->height * 127;
	is($submat->sum->[0], $s2);

	if ($verbose) {
		$src->show($win);
		Cv->waitKey(100);
	}

	my $s3 = $submat->width * $submat->height * 255;
	is($src->sum->[0], $s1 + $s2 - $s3);

	$submat = undef;
	is($src->sum->[0], $s1 + $s2 - $s3);

	foreach (
		{ rect => [ $x - 80, $y - 60, $w, $h ], color => [ 255, 128, 196 ] },
		{ rect => [ $x + 80, $y - 60, $w, $h ], color => [ 196, 255, 128 ] },
		{ rect => [ $x + 80, $y + 60, $w, $h ], color => [ 255, 196, 128 ] },
		{ rect => [ $x - 80, $y + 60, $w, $h ], color => [ 196, 128, 255 ] },
		) {
		$submat = $src->GetSubRect($_->{rect});
		$submat->fill($_->{color});
	}

	if ($verbose) {
		$src->show($win);
		Cv->waitKey(100);
	}

	$src;
}
