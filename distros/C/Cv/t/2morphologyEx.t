# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 17;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

#  void cvMorphologyEx(src, dst, temp, element, operation, iterations=1)
#  (1) $src->MorphologyEx($element, CV_MOP_OPEN);
#  (2) $src->MorphologyEx($element, CV_MOP_TOPHAT);
#  (3) $src->MorphologyEx($dst, $tmp, $element, CV_MOP_BLACKHAT);

if (1) {
	my $element = Cv->CreateStructuringElementEx(3, 3, 1, 1, CV_SHAPE_RECT);
	my $av;
	no strict 'refs';
	no warnings 'redefine';
	local *Cv::Arr::cvMorphologyEx = sub { $av = \@_; $_[0]; };
	my $src = Cv->CreateImage([ 320, 240 ], 8, 3);
	$src->MorphologyEx($element, CV_MOP_OPEN);
	is($av->[0], $src);
	is(ref $av->[1], ref $src);
	is($av->[2], undef);
	is($av->[3], $element);
	is($av->[4], CV_MOP_OPEN);
}

if (2) {
	my $element = Cv->CreateStructuringElementEx(3, 3, 1, 1, CV_SHAPE_RECT);
	my $av;
	no strict 'refs';
	no warnings 'redefine';
	local *Cv::Arr::cvMorphologyEx = sub { $av = \@_; $_[0]; };
	my $src = Cv->CreateImage([ 320, 240 ], 8, 3);
	$src->MorphologyEx($element, CV_MOP_TOPHAT);
	is($av->[0], $src);
	is(ref $av->[1], ref $src);
	is(ref $av->[2], ref $src);
	is($av->[3], $element);
	is($av->[4], CV_MOP_TOPHAT);
}

if (3) {
	my $element = Cv->CreateStructuringElementEx(3, 3, 1, 1, CV_SHAPE_RECT);
	my $av;
	no strict 'refs';
	no warnings 'redefine';
	local *Cv::Arr::cvMorphologyEx = sub { $av = \@_; $_[0]; };
	my $src = Cv->CreateImage([ 320, 240 ], 8, 3);
	my $dst = $src->new;
	my $tmp = $src->new;
	$src->MorphologyEx($dst, $tmp, $element, CV_MOP_BLACKHAT);
	is($av->[0], $src);
	is($av->[1], $dst);
	is($av->[2], $tmp);
	is($av->[3], $element);
	is($av->[4], CV_MOP_BLACKHAT);
}

if (10) {
	my $src = Cv::Mat->new([ 240, 320 ], CV_8UC3);
	throws_ok { $src->MorphologyEx } qr/Usage: Cv::Arr::cvMorphologyEx\(src, dst, temp, element, operation, iterations=1\) at $0/;
}
