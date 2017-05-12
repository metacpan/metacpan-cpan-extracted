# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 721;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my %TYPENAME = (
	'Cv::Mat'       => CV_TYPE_NAME_MAT,
	'Cv::Image'     => CV_TYPE_NAME_IMAGE,
	'Cv::MatND'     => CV_TYPE_NAME_MATND,
	'Cv::SparseMat' => CV_TYPE_NAME_SPARSE_MAT,
	);

my %RELEASE = (
	'Cv::Mat'       => \&Cv::Mat::cvReleaseMat,
	'Cv::Image'     => \&Cv::Image::cvReleaseImage,
	'Cv::MatND'     => \&Cv::MatND::cvReleaseMatND,
	'Cv::SparseMat' => \&Cv::SparseMat::cvReleaseSparseMat,
	);

for my $class (keys %TYPENAME) {
	# structure member: $arr->{structure_member}
	if (1) {
		my $arr = $class->new(my $sizes = [240, 320], my $type = CV_8UC3);
		isa_ok($arr, $class, "${class}->new");
		my $type_name = Cv->TypeOf($arr)->type_name;
		is($type_name, $TYPENAME{$class});
		is($arr->rows,   $sizes->[0], "${class}->rows");
		is($arr->cols,   $sizes->[1], "${class}->cols");
		is($arr->height, $sizes->[0], "${class}->height");
		is($arr->width,  $sizes->[1], "${class}->width");
		is($arr->dims, scalar @$sizes, "${class}->dims");
		is_deeply([$arr->getDims], $sizes, "${class}->getDims");
		is_deeply($arr->sizes, $sizes, "${class}->sizes");
		is($arr->type, $type, "${class}->type");
		is($arr->depth, CV2IPL_DEPTH($type), "${class}->depth");
		is($arr->channels, CV_MAT_CN($type), "${class}->channels");
		is($arr->nChannels, CV_MAT_CN($type), "${class}->nChannels");
		throws_ok { $arr->unknown } qr/can't call ${class}::unknown/, "${class}->unknwon at $0";
	}

	# type: Cv::Mat->new([ $rows, $cols ], $type);
	if (2) {
		my @type;
		for my $depth (CV_8U, CV_8S, CV_16S, CV_16U, CV_32S, CV_32F, CV_64F) {
			push(@type, CV_MAKETYPE($depth, $_)) for 1 .. 4;
		}
		for (map { +{ sizes => [240, 320], type => $_ } } @type) {
			my $arr = $class->new($_->{sizes}, $_->{type});
			isa_ok($arr, $class, "${class}->new");
			is($arr->type, $_->{type}, "${class}->type");
			is_deeply($arr->sizes, $_->{sizes}, "${class}->sizes");
			is(scalar $arr->getDims(\my @sizes), scalar @{$_->{sizes}},
			   "scalar ${class}->getDims");
			is_deeply(\@sizes, $_->{sizes}, "${class}->getDims(\@sizes)");
		}
		throws_ok { $class->new } qr/size not specified in ${class}::new at $0/;
		throws_ok { $class->new([320, 240]) } qr/type not specified in ${class}::new at $0/;
	}

	# inherit parameters if omit
	if (3) {
		my $arr = $class->new([240, 320], CV_8UC3);
		isa_ok($arr, $class, "${class}->new");
		my $arr2 = $arr->new;
		is(ref $arr2, $class, "${class}->new(): ?class");
		is_deeply($arr2->sizes, $arr->sizes, "${class}->new(): ?sizes");
		is($arr2->type, $arr->type, "${class}->new(): ?type");
		my $arr3 = $arr->new(my $type = CV_8UC1);
		is(ref $arr3, ref $arr, "${class}->new(type): ?class");
		is_deeply($arr3->sizes, $arr->sizes, "${class}->new(type): ?sizes");
		is($arr3->type, $type, "${class}->new(type): ?type");
		my $arr4 = $arr->new(my $sizes = [480, 640]);
		is(ref $arr4, ref $arr, "${class}->new(sizes): ?class");
		is_deeply($arr4->sizes, $sizes, "${class}->new(sizes): ?sizes");
		is($arr4->type, $arr->type, "${class}->new(sizes): ?type");
	}

	# ${class}::Ghost
	if (4) {
		no warnings 'redefine';
		no strict 'refs';
		my $destroy = 0;
		my $destroy_ghost = 0;
		my $release = $RELEASE{$class};
		local *{"${class}::DESTROY"} = sub { $destroy++ };
		local *{"${class}::Ghost::DESTROY"} = sub {
			$destroy_ghost++;
			&{$release}($_[0]);
			is(ref $_[0], 'SCALAR', "$release");
		};
		my $arr = $class->new([ 16, 16 ], CV_8UC1);
		isa_ok($arr, $class);
		bless $arr, "${class}::Ghost";
		$arr = undef;
		is($destroy, 0, "${class}->DESTROY");
		is($destroy_ghost, 1, "${class}::Ghost->DESTROY");
	}

	# XXXXX - This test case attempted to test that there is no memory
	# leak, but it was not enough.
	# see cpan/report/bf57696e-7ed6-11e2-9fc8-389cbe3604bd
	if (0) {
		my $arr = $class->new(my $sizes = [240, 320], my $type = CV_8UC3);
		isa_ok($arr, $class);
		my $arr_phys = $arr->phys;
		$arr->DESTROY;
		my $arr2 = $class->new($sizes, $type);
		isa_ok($arr2, $class);
		my $arr2_phys = $arr2->phys;
		is($arr2_phys, $arr_phys);
	}
}

for my $src_class (keys %TYPENAME) {
	my $src = $src_class->new([240, 320], CV_32FC2);

	if (6) {
		for my $dst_class (keys %TYPENAME) {
			my $new = "${dst_class}::new";
			my $dst = $src->$new;
			is_deeply($dst->sizes, $src->sizes);
			is_deeply($dst->type, $src->type);
		}
	}

	if (7) {
		for my $dst_class (qw(Cv::Seq Cv::Seq::Point)) {
			my $stor = Cv::MemStorage->new;
			my $new = "${dst_class}::new";
			my $seq = $src->$new($stor);
			is($seq->mat_type, $src->type);
		}
	}

}
