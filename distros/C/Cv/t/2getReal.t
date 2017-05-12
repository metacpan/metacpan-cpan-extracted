# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 33;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ------------------------------------------------------------
# double cvGetReal1D(const CvArr* arr, int idx0)
# double cvGetReal2D(const CvArr* arr, int idx0, int idx1)
# double cvGetReal3D(const CvArr* arr, int idx0, int idx1, int idx2)
# double cvGetRealND(const CvArr* arr, int* idx)
# ------------------------------------------------------------

if (1) {
	my $Xs = 'GetRealND';
	(my $xs = $Xs) =~ s/^[A-Z]+/\L$&/;

	my $src = Cv::MatND->new([ 320, 240, 2 ], CV_64FC1);

	no warnings 'redefine';
	no strict 'refs';

	my $idx0 = int rand $src->rows;
	my $idx1 = int rand $src->cols;

	my @got = ();
	local *{"Cv::core::cv$Xs"} = sub { @got = @_ };
	&{"Cv::core::cv$Xs"}($src, [$idx0, $idx1]);
	is(scalar @got, 2, "cv$Xs: scalar \@got");
	is($got[0], $src, "cv$Xs: src");
	is($got[1]->[0], $idx0, "cv$Xs: idx0");
	is($got[1]->[1], $idx1, "cv$Xs: idx1");

	local *{"Cv::Arr::cv$Xs"} = *{"Cv::core::cv$Xs"};
	# local *{"Cv::cv$Xs"} = *{"Cv::core::cv$Xs"};
	foreach my $fn ("GetReal", "getReal") {
		@got = ();
		$src->$fn($idx0, $idx1);
		is(scalar @got, 2, "cv$Xs: scalar \@got");
		is($got[0], $src, "cv$Xs: src");
		is(@{$got[1]}, $src->dims, "cv$Xs: src.dims");
		is($got[1]->[0], $idx0, "cv$Xs: idx0");
		is($got[1]->[1], $idx1, "cv$Xs: idx1");
		is($got[1]->[2], 0, "cv$Xs: idx1");

		@got = ();
		$src->$fn([$idx0, $idx1]);
		is(scalar @got, 2, "cv$Xs: scalar \@got");
		is($got[0], $src, "cv$Xs: src");
		is(@{$got[1]}, $src->dims, "cv$Xs: src.dims");
		is($got[1]->[0], $idx0, "cv$Xs: idx0");
		is($got[1]->[1], $idx1, "cv$Xs: idx1");
		is($got[1]->[2], 0, "cv$Xs: idx1");
	}
}

for my $n (1..4) {
	my $m = Cv::Mat->new([240, 320], CV_64FC($n));
	my $v = cvScalar(map { rand 1 } 1..$n);
	my $i = [map { int rand $_ } @{$m->sizes}];
	$m->set($i, $v);
	if ($n == 1) {
		is($m->getReal($i), $v->[0]);
	} else {
		throws_ok { $m->getReal($i) } qr/OpenCV Error:/;
	}
}
