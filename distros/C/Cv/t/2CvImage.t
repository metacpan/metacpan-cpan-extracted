# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 89;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $class = 'Cv::Image';

# structure member: $obj->{structure_member}
if (1) {
	my $arr = $class->new(my $sizes = [240, 320], my $type = CV_8UC3);
	isa_ok($arr, $class);
	is_deeply($arr->size, [$arr->width, $arr->height], "size");

	is($arr->origin, 0);
	$arr->origin(1);
	is($arr->origin, 1);
	$arr->origin(0);
	is($arr->origin, 0);

	throws_ok { ${class}->new([240, 320], 7) } qr/OpenCV Error:/;
}

# type: $class->new([ $rows, $cols ], $type);
if (2) {
	throws_ok { $class->new([-1, -1], CV_8UC3) } qr/OpenCV Error:/;
}


# ------------------------------------------------------------
# CvRect cvGetImageROI(const IplImage* image)
# void cvResetImageROI(IplImage* image)
# void cvSetImageROI(IplImage* image, CvRect rect)
# ------------------------------------------------------------

if (10) {
	my $image = ${class}->new([240, 320], CV_8UC3);
	isa_ok($image, ${class});
	my $sz = $image->size;
	my $roi = [0, 0, @$sz];
	is_deeply($image->roi, $roi);
}

if (11) {
	my $image = ${class}->new([240, 320], CV_8UC3);
	isa_ok($image, ${class});
	$image->SetImageROI(my $roi = [10, 20, 30, 40]);
	is_deeply($image->GetImageROI, $roi);
}

if (12) {
	my $image = ${class}->new([240, 320], CV_8UC3);
	isa_ok($image, ${class});
	$image->roi(my $roi = [10, 20, 30, 40]);
	is_deeply($image->roi, $roi);
	$image->ResetImageROI;
	$roi = [0, 0, $image->width, $image->height];
	is_deeply($image->roi, $roi);
}


# ------------------------------------------------------------
# int cvGetImageCOI(const IplImage* image)
# void cvSetImageCOI(IplImage* image, int coi)
# ------------------------------------------------------------

if (21) {
	my $arr = ${class}->new([3, 4], CV_8UC3);
	isa_ok($arr, ${class});
	$arr->fill([1, 2, 3]);
	is($arr->coi, 0);

	foreach my $coi (1 .. 3) {
		$arr->coi($coi);
		foreach my $row (0 .. $arr->rows - 1) {
			foreach my $col (0 .. $arr->cols - 1) {
				is(${$arr->get([$row, $col])}[0], 1);
			}
		}
	}

	$arr->coi(0);
	foreach my $row (0 .. $arr->rows - 1) {
		foreach my $col (0 .. $arr->cols - 1) {
			is(${$arr->get([$row, $col])}[0], 1);
			is(${$arr->get([$row, $col])}[1], 2);
			is(${$arr->get([$row, $col])}[2], 3);
		}
	}
}

