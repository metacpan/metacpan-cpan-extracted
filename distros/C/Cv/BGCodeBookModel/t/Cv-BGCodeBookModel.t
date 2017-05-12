# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 22;
use Test::Exception;
BEGIN { use_ok('Cv', -bg) }

# ============================================================
#  CvBGCodeBookModel* cvCreateBGCodeBookModel
# ============================================================

can_ok('Cv::BGCodeBookModel', 'cvCreateBGCodeBookModel');
if (1) {
	my $model = Cv::BGCodeBookModel::cvCreateBGCodeBookModel();
	isa_ok($model, 'Cv::BGCodeBookModel');
	ok(scalar grep /cvCreateBGCodeBookModel/, @Cv::BGCodeBookModel::EXPORT_OK);
}

can_ok('Cv', 'cvCreateBGCodeBookModel');
if (1) {
	my $model = Cv::cvCreateBGCodeBookModel();
	isa_ok($model, 'Cv::BGCodeBookModel');
	ok(scalar grep /cvCreateBGCodeBookModel/, @Cv::EXPORT_OK);
}

can_ok('Cv', 'CreateBGCodeBookModel');
if (1) {
	my $model = Cv->CreateBGCodeBookModel();
	isa_ok($model, 'Cv::BGCodeBookModel');
}

can_ok('Cv::BGCodeBookModel', 'new');
if (1) {
	my $model = Cv::BGCodeBookModel->new;
	isa_ok($model, 'Cv::BGCodeBookModel');
}

can_ok(__PACKAGE__, 'cvCreateBGCodeBookModel');


# ============================================================
#  cvBGCodeBookClearStale cvBGCodeBookDiff cvBGCodeBookUpdate
#  cvSegmentFGMask
# ============================================================

if (1) {
	for (qw( cvBGCodeBookClearStale cvBGCodeBookDiff cvBGCodeBookUpdate cvSegmentFGMask)) {
		package Cv::BGCodeBookModel;
		no strict 'refs';
		no warnings 'redefine';
		my $pass = 0;
		local *$_ = sub { $pass++ };
		(my $short1 = $_) =~ s/^cv//;
		(my $short2 = $_) =~ s/^cv|BGCodeBook//g;
		&$short1;
		main::is($pass, 1, "$short1: alias of $_");
		if ($short1 ne $short2) {
			&$short2;
			main::is($pass, 2, "$short2: alias of $_");
		}
	}
}

# ============================================================
#  AV* modMin(CvBGCodeBookModel* model, AV* value = NO_INIT)
#  AV* modMax(CvBGCodeBookModel* model, AV* value = NO_INIT)
#  AV* cbBounds(CvBGCodeBookModel* model, AV* value = NO_INIT)
#  int t(CvBGCodeBookModel* model)
# ============================================================

if (1) {
	my $model = Cv::BGCodeBookModel->new;
	$model->modMin(my $min = [ map { int rand 256 } 1, 2, 3 ]);
	is_deeply($model->modMin, $min);
	$model->modMax(my $max = [ map { int rand 256 } 1, 2, 3 ]);
	is_deeply($model->modMax, $max);
	$model->cbBounds(my $bounds = [ map { int rand 256 } 1, 2, 3 ]);
	is_deeply($model->cbBounds, $bounds);
	$model->can('t');
}
