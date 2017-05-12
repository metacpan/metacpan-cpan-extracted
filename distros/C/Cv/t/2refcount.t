# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 19;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

if (1) {
	my $mat = Cv::Mat->new([10, 10], CV_32FC1);
	ok($mat);
	is(ref $mat, 'Cv::Mat');
	is($mat->refcount, 1);
	Cv::Mat::cvReleaseMat($mat);
	is(ref $mat, 'SCALAR');
	throws_ok { Cv::Mat::refcount($mat) } qr/mat is not of type CvMat \* in Cv::Mat::refcount at $0/;
	throws_ok { Cv::Mat::DESTROY($mat) } qr/mat is not of type CvMat \* in Cv::Mat::cvReleaseMat at $0/;
}

if (2) {
	my $mat = Cv::MatND->new([10, 10], CV_32FC1);
	ok($mat);
	is(ref $mat, 'Cv::MatND');
	is($mat->refcount, 1);
	Cv::MatND::cvReleaseMatND($mat);
	is(ref $mat, 'SCALAR');
	throws_ok { Cv::MatND::refcount($mat) } qr/mat is not of type CvMatND \* in Cv::MatND::refcount at $0/;
	throws_ok { Cv::MatND::DESTROY($mat) } qr/mat is not of type CvMatND \* in Cv::MatND::cvReleaseMatND at $0/;
}

if (3) {
	my $mat = Cv::SparseMat->new([10, 10], CV_32FC1);
	ok($mat);
	is(ref $mat, 'Cv::SparseMat');
  TODO: {
	  local $TODO = "fix refcount (value of refcount is -1)";
	  is($mat->refcount, 1);
	}
	Cv::SparseMat::cvReleaseSparseMat($mat);
	is(ref $mat, 'SCALAR');
	throws_ok { Cv::SparseMat::refcount($mat) } qr/mat is not of type CvSparseMat \* in Cv::SparseMat::refcount at $0/;
	throws_ok { Cv::SparseMat::DESTROY($mat) } qr/mat is not of type CvSparseMat \* in Cv::SparseMat::cvReleaseSparseMat at $0/;
}
