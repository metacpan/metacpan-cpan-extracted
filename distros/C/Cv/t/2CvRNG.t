# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 11;
use Test::Number::Delta within => 1e-1;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

# ------------------------------------------------------------
#  CvRNG* cvRNG(int64 seed = -1)
#  void cvRandArr(CvRNG* rng, CvArr* arr, int distType, CvScalar param1, CvScalar param2)
# ------------------------------------------------------------

if (1) {
	my $rng = Cv->RNG(-1);
	ok($rng);
	ok($rng->isa("Cv::RNG"));
}

if (2) {
	my $rng = Cv->RNG;
	my ($p1, $p2) = (127, 64);
	my $ch = 3;
	my $retval = $rng->arr(
		my $arr = Cv::Image->new([240, 320], CV_8UC($ch)),
		CV_RAND_NORMAL,
		cvScalarAll($p1),
		cvScalarAll($p2)
		);
	is($retval, $arr);
	if ($verbose) {
		$arr->Show("rng");
		Cv->WaitKey(1000);
	}
	$arr->avgSdv(my $mean, my $stdDev);
	my @mean = map { $_ / $p1 } @{$mean}[0 .. $ch - 1];
	my @stdDev = map { $_ / $p2 } @{$stdDev}[0 .. $ch - 1];
	delta_ok(\@mean, [ (1.0) x $ch ]);
	delta_ok(\@stdDev, [ (1.0) x $ch ]);
}

if (2) {
	my $rng = Cv->RNG;
	my ($p1, $p2) = (1, 1);
	my $ch = 4;
	my $retval = $rng->arr(
		my $arr = Cv::Image->new([240, 320], CV_32FC($ch)),
		CV_RAND_NORMAL,
		cvScalarAll($p1),
		cvScalarAll($p2)
		);
	is($retval, $arr);
	if ($verbose) {
		$arr->Show("rng");
		Cv->WaitKey(1000);
	}
	$arr->avgSdv(my $mean, my $stdDev);
	my @mean = map { $_ / $p1 } @{$mean}[0 .. $ch - 1];
	my @stdDev = map { $_ / $p2 } @{$stdDev}[0 .. $ch - 1];
	delta_ok(\@mean, [ (1.0) x $ch ]);
	delta_ok(\@stdDev, [ (1.0) x $ch ]);
}

if (10) {
	my $rng = Cv->RNG;
	throws_ok { $rng->arr } qr/Usage: Cv::RNG::cvArr\(rng, arr, distType, param1, param2\) at $0/;
}

if (11) {
	my $rng = Cv->RNG;
	throws_ok { $rng->arr(1,2,3,4) } qr/arr is not of type CvArr \* in Cv::RNG::cvRandArr at $0/;
}
