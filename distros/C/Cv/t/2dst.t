# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 575;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }


#  (1) $src1->XXX($src2);
#  (2) $src1->XXX($val2);
#  (3) $src1->XXX($src2, $dst);
#  (4) $src1->XXX($src2); # new returns undef

foreach my $xs (qw(

AbsDiff Add And Or Sub Xor

)) {

	if (1) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[2]; };
		my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $src2 = Cv->CreateImage([ 320, 240 ], 8, 3);
		eval { $src1->$xs($src2); };
		is($av[0], $cv,   "$xs-1.0");
		is($av[1], $src1, "$xs-1.1");
		is($av[2], $src2, "$xs-1.2");
	}

	if (2) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}S";
		local *$cv = sub { @av = ($cv, @_); $_[2]; };
		my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $val2 = [ 1, 2, 3 ];
		eval { $src1->$xs($val2); };
		is($av[0], $cv,   "$xs-2.0");
		is($av[1], $src1, "$xs-2.1");
		is($av[2], $val2, "$xs-2.2");
	}

	if (3) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[2]; };
		my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $src2 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $dst = $src1->new;
		my $ret = eval { $src1->$xs($src2, $dst); };
		is($av[0], $cv,   "$xs-3.0");
		is($av[1], $src1, "$xs-3.1");
		is($av[2], $src2, "$xs-3.2");
		is($av[3], $dst,  "$xs-3.3");
		is($ret,   $dst,  "$xs-3.r");
	}

	if (4) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[2]; };
		my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $src2 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $new = join('::', ref $src1, 'new');
		local *$new = sub { undef; };
		my $ret = eval { $src1->$xs($src2); };
		is($av[0], $cv,   "$xs-4.0");
		is($av[1], $src1, "$xs-4.1");
		is($av[2], $src2, "$xs-4.2");
		is($ret,   undef, "$xs-4.r");
	}

	if (10) {
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		throws_ok { &$cv() } qr/Usage: $cv/;
	}

	if (11) {
		my $src1 = Cv::Mat->new([ 10, 10 ], CV_32FC1);
		my $src2 = Cv::Mat->new([ 11, 11 ], CV_32FC1);
		my $dst  = Cv::Mat->new([ 12, 12 ], CV_32FC1);
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		throws_ok { &$cv($src1, $src2, $dst) } qr/OpenCV Error:/;
	}
}



#  (1) $src1->XXX();
#  (3) $src1->XXX($dst);
#  (4) $src1->XXX(); # new returns undef

# WarpAffine
# WarpPerspective

foreach my $xs (qw(

ConvertScale ConvertScaleAbs DCT DFT Exp Flip Inv Log Normalize Not
Pow Reduce Repeat Transpose CopyMakeBorder Dilate Erode Filter2D
Laplace MorphologyEx PyrDown PyrUp Smooth Sobel LinearPolar LogPolar
Remap Resize AdaptiveThreshold DistTransform EqualizeHist Integral
PyrMeanShiftFiltering PyrSegmentation Threshold Canny

)) {

	SKIP: {
		unless (Cv::Arr->can("cv${xs}")) {
			diag "skipping ${xs}() - OpenCV-", join('.', CV_VERSION);
			skip "no $xs", 10;
		}

		if (1) {
			my @av;
			no warnings;
			no strict 'refs';
			my $cv = "Cv::Arr::cv${xs}";
			local *$cv = sub { @av = ($cv, @_); $_[1]; };
			my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
			eval { $src1->$xs(); };
			is($av[0], $cv,   "$xs-11.0");
			is($av[1], $src1, "$xs-11.1");
		}

		if (3) {
			my @av;
			no warnings;
			no strict 'refs';
			my $cv = "Cv::Arr::cv${xs}";
			local *$cv = sub { @av = ($cv, @_); $_[1]; };
			my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
			my $dst = $src1->new;
			my $ret = eval { $src1->$xs($dst); };
			is($av[0], $cv,   "$xs-13.0");
			is($av[1], $src1, "$xs-13.1");
			is($av[2], $dst,  "$xs-13.2");
			is($ret,   $dst,  "$xs-13.r");
		}

		if (4) {
			my @av;
			no warnings;
			no strict 'refs';
			my $cv = "Cv::Arr::cv${xs}";
			local *$cv = sub { @av = ($cv, @_); $_[1]; };
			my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
			my $new = join('::', ref $src1, 'new');
			local *$new = sub { undef; };
			my $ret = eval { $src1->$xs(); };
			is($av[0], $cv,   "$xs-14.0");
			is($av[1], $src1, "$xs-14.1");
			is($ret,   undef, "$xs-14.r");
		}

		if (10) {
			no strict 'refs';
			my $cv = "Cv::Arr::cv${xs}";
			throws_ok { &$cv() } qr/Usage: $cv/;
		}
	}
}



#  (1) $src1->XXX($src2);
#  (3) $src1->XXX($src2, $dst);
#  (4) $src1->XXX($src2); # new returns undef

foreach my $xs (
	qw(CrossProduct Div Mul MulSpectrums MulTransposed),
	# qw(Solve SubRS Inpaint),
	qw(SubRS Inpaint),
) {

	if (1) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[2]; };
		my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $src2 = Cv->CreateImage([ 320, 240 ], 8, 3);
		eval { $src1->$xs($src2); };
		is($av[0], $cv,   "$xs-21.0");
		is($av[1], $src1, "$xs-21.1");
		is($av[2], $src2, "$xs-21.2");
	}

	if (3) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[2]; };
		my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $src2 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $dst = $src1->new;
		my $ret = eval { $src1->$xs($src2, $dst); };
		is($av[0], $cv,   "$xs-23.0");
		is($av[1], $src1, "$xs-23.1");
		is($av[2], $src2, "$xs-23.2");
		is($av[3], $dst,  "$xs-23.3");
		is($ret,   $dst,  "$xs-23.r");
	}

	if (4) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[2]; };
		my $src1 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $src2 = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $new = join('::', ref $src1, 'new');
		local *$new = sub { undef; };
		my $ret = eval { $src1->$xs($src2); };
		is($av[0], $cv,   "$xs-24.0");
		is($av[1], $src1, "$xs-24.1");
		is($av[2], $src2, "$xs-24.2");
		is($ret,   undef, "$xs-24.r");
	}

	if (10) {
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		throws_ok { &$cv() } qr/Usage: $cv/;
	}

}


#  (1) $src->XXX($arr_upper, $arr_lower);
#  (2) $src->XXX($arr_upper, $arr_lower, $dst);
#  (3) $src->XXX($val_upper, $val_lower);
#  (4) $src->XXX($val_upper, $val_lower, $dst);

foreach my $xs (qw(

InRange

)) {

	if (1) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[4]; };
		my $src = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $upper = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $lower = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $ret = eval { $src->$xs($upper, $lower); };
		is($av[0], $cv,    "$xs-31.0");
		is($av[1], $src,   "$xs-31.1");
		is($av[2], $upper, "$xs-31.2");
		is($av[3], $lower, "$xs-31.3");
		isa_ok($av[4], ref $src, "$xs-31.4");
	}

	if (2) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		local *$cv = sub { @av = ($cv, @_); $_[4]; };
		my $src = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $upper = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $lower = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $dst = $src->new;
		my $ret = eval { $src->$xs($upper, $lower, $dst); };
		is($av[0], $cv,    "$xs-32.0");
		is($av[1], $src,   "$xs-32.1");
		is($av[2], $upper, "$xs-32.2");
		is($av[3], $lower, "$xs-32.3");
		is($av[4], $dst,   "$xs-32.4");
	}

	if (3) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}S";
		local *$cv = sub { @av = ($cv, @_); $_[4]; };
		my $src = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $upper = [ 201 .. 203 ];
		my $lower = [ 101 .. 103 ];
		my $ret = eval { $src->$xs($upper, $lower); };
		is($av[0], $cv,    "$xs-33.0");
		is($av[1], $src,   "$xs-33.1");
		is($av[2], $upper, "$xs-33.2");
		is($av[3], $lower, "$xs-33.3");
		isa_ok($av[4], ref $src, "$xs-33.4");
	}

	if (4) {
		my @av;
		no warnings;
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}S";
		local *$cv = sub { @av = ($cv, @_); $_[4]; };
		my $src = Cv->CreateImage([ 320, 240 ], 8, 3);
		my $upper = [ 201 .. 203 ];
		my $lower = [ 101 .. 103 ];
		my $dst = $src->new;
		my $ret = eval { $src->$xs($upper, $lower, $dst); };
		is($av[0], $cv,    "$xs-34.0");
		is($av[1], $src,   "$xs-34.1");
		is($av[2], $upper, "$xs-34.2");
		is($av[3], $lower, "$xs-34.3");
		is($av[4], $dst,   "$xs-34.4");
	}

	if (10) {
		no strict 'refs';
		my $cv = "Cv::Arr::cv${xs}";
		throws_ok { &$cv() } qr/Usage: $cv/;
	}

}
