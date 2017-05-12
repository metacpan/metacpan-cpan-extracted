# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 3;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

# ------------------------------------------------------------
#  void cvDFT(const CvArr* src, CvArr* dst, int flags, int nonzeroRows=0)
# ------------------------------------------------------------

my $src = Cv::Image->new([100, 100], CV_64FC1);
for my $i (0 .. $src->rows - 1) {
	for my $j (0 .. $src->cols - 1) {
		my ($x, $y) = ($i / $src->rows, $j / $src->cols);
		$src->set([$i, $j], [sqrt($x * $x + $y * $y)]);
	}
}

if (1) {
	my $A = Cv->Merge(
		$src->Scale($src->new(CV_64FC1)),
		$src->new(CV_64FC1)->Zero,
		);
	my $dft = $A->new([cvGetOptimalDFTSize($A->rows - 1),
					   cvGetOptimalDFTSize($A->cols - 1)],
		);
	# copy $A to $dft and pad $dft with zeros
	my $tmp = $A->copy($dft->GetSubRect([0, 0, @{$A->size}]));
	if ($dft->cols > $A->cols) {
		$dft->GetSubRect($tmp, [$A->cols, 0, $dft->cols - $A->cols, $A->rows]);
		$tmp->Zero;
	}
	my ($re, $im) = $dft->DFT(CV_DXT_FORWARD, $src->rows)->split;
	if ($verbose) {
		$im->show("dft.im");
		Cv->waitKey(1000);
	}
}

if (10) {
	throws_ok { $src->DFT() } qr/Usage: Cv::Arr::cvDFT\(src, dst, flags, nonzeroRows=0\) at $0/;
}

if (11) {
	throws_ok { $src->DFT(\0, CV_DXT_FORWARD) } qr/OpenCV Error:/;
}
