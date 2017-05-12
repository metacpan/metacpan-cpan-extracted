# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 9;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $src = Cv->createImage([ 320, 240 ], 8, 3);
my $rng = Cv->RNG;
$rng->randArr($src, CV_RAND_NORMAL, cvScalarAll(0), cvScalarAll(255));

if (1) {
	my $dst2 = Cv::Arr::Copy($src, my $dst = $src->new);
	my ($s, $d1, $d2) = ($src->sum, $dst->sum, $dst2->sum);
	is_deeply($s, $d1);
	is_deeply($s, $d2);
}

if (2) {
	my $dst2 = $src->Copy(my $dst = $src->new);
	my ($s, $d1, $d2) = ($src->sum, $dst->sum, $dst2->sum);
	is_deeply($s, $d1);
	is_deeply($s, $d2);
}

if (3) {
	my $dst2 = $src->copy(my $dst = $src->new);
	my ($s, $d1, $d2) = ($src->sum, $dst->sum, $dst2->sum);
	is_deeply($s, $d1);
	is_deeply($s, $d2);
}

if (10) {
	throws_ok { $src->copy } qr/Usage: Cv::Arr::cvCopy\(src, dst, mask=NULL\) at $0/;
}

if (11) {
	throws_ok { $src->copy($src->new(CV_8UC1)) } qr/OpenCV Error:/;
}
