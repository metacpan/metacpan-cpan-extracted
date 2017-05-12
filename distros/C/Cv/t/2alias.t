# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 97;
BEGIN { use_ok('Cv', -nomore, -bg, '/do not import/') }

if (1) {
	for (qw(cvScalar cvVersion)) {
		ok(!__PACKAGE__->can($_));
	}
}

if (99) {
	# A-G
	ok(Cv->assoc('CreateBGCodeBookModel'));
	ok(Cv::BGCodeBookModel->Cv::assoc('new'));
	ok(Cv::BGCodeBookModel->Cv::assoc('Update'));
	ok(Cv::BGCodeBookModel->Cv::assoc('Diff'));
	ok(Cv::BGCodeBookModel->Cv::assoc('ClearStale'));

	ok(Cv->assoc('CreateStructuringElementEx'));
	ok(Cv::ConvKernel->Cv::assoc('new'));

	ok(Cv->assoc('OpenFileStorage'));
	ok(Cv::FileStorage->Cv::assoc('new'));

	ok(Cv->assoc('InitFont'));
	ok(Cv::Font->Cv::assoc('new'));

	# H-N
	ok(Cv->assoc('LoadHaarClassifierCascade'));
	ok(Cv::HaarClassifierCascade->Cv::assoc('new'));

	ok(Cv::Histogram->Cv::assoc('Calc'));
	ok(Cv::Histogram->Cv::assoc('Clear'));
	ok(Cv::Histogram->Cv::assoc('Compare'));
	ok(Cv::Histogram->Cv::assoc('Normalize'));
	# ok(Cv::Histogram->Cv::assoc('SetBinRanges'));
	ok(Cv::Histogram->Cv::assoc('SetRanges'));
	ok(Cv::Histogram->Cv::assoc('Thresh'));

	ok(Cv::Image->Cv::assoc('Clear'));
	ok(Cv::Image->Cv::assoc('Clone'));
	ok(Cv::Image->Cv::assoc('CloneImage'));
	ok(Cv::Image->Cv::assoc('GetCOI'));
	ok(Cv::Image->Cv::assoc('GetImageCOI'));
	ok(Cv::Image->Cv::assoc('GetImageROI'));
	ok(Cv::Image->Cv::assoc('GetROI'));
	ok(Cv::Image->Cv::assoc('ResetImageROI'));
	ok(Cv::Image->Cv::assoc('ResetROI'));
	ok(Cv::Image->Cv::assoc('SetCOI'));
	ok(Cv::Image->Cv::assoc('SetImageCOI'));
	ok(Cv::Image->Cv::assoc('SetImageROI'));
	ok(Cv::Image->Cv::assoc('SetROI'));

	ok(Cv->assoc('CreateKalman'));
	ok(Cv::Kalman->Cv::assoc('new'));
	ok(Cv::Kalman->Cv::assoc('MP'));
	ok(Cv::Kalman->Cv::assoc('DP'));
	ok(Cv::Kalman->Cv::assoc('CP'));
	ok(Cv::Kalman->Cv::assoc('state_pre'));
	ok(Cv::Kalman->Cv::assoc('state_post'));
	ok(Cv::Kalman->Cv::assoc('transition_matrix'));
	ok(Cv::Kalman->Cv::assoc('control_matrix'));
	ok(Cv::Kalman->Cv::assoc('measurement_matrix'));
	ok(Cv::Kalman->Cv::assoc('process_noise_cov'));
	ok(Cv::Kalman->Cv::assoc('measurement_noise_cov'));
	ok(Cv::Kalman->Cv::assoc('error_cov_pre'));
	ok(Cv::Kalman->Cv::assoc('gain'));
	ok(Cv::Kalman->Cv::assoc('error_cov_post'));
	ok(Cv::Kalman->Cv::assoc('KalmanCorrect'));
	ok(Cv::Kalman->Cv::assoc('KalmanPredict'));

	ok(Cv->assoc('CreateMemStorage'));
	ok(Cv::MemStorage->Cv::assoc('new'));
	ok(Cv::MemStorage->Cv::assoc('bottom'));
	ok(Cv::MemStorage->Cv::assoc('top'));
	ok(Cv::MemStorage->Cv::assoc('parent'));
	ok(Cv::MemStorage->Cv::assoc('block_size'));
	ok(Cv::MemStorage->Cv::assoc('free_space'));
	ok(Cv::MemStorage->Cv::assoc('ClearMemStorage'));
	ok(Cv::MemStorage->Cv::assoc('Clear'));
	ok(Cv::MemStorage->Cv::assoc('CreateChildMemStorage'));
	ok(Cv::MemStorage->Cv::assoc('MemStorageAlloc'));
	ok(Cv::MemStorage->Cv::assoc('AllocString'));
	ok(Cv::MemStorage->Cv::assoc('Clear'));
	ok(Cv::MemStorage->Cv::assoc('MemStorageAllocString'));

	ok(Cv->assoc('CreateMat'));
	ok(Cv::Mat->Cv::assoc('new'));
	ok(Cv::Mat->Cv::assoc('refcount'));
	ok(Cv::Mat->Cv::assoc('Clear'));
	ok(Cv::Mat->Cv::assoc('Clone'));
	ok(Cv::Mat->Cv::assoc('CloneMat'));

	ok(Cv->assoc('CreateMatND'));
	ok(Cv::MatND->Cv::assoc('new'));
	ok(Cv::MatND->Cv::assoc('refcount'));
	ok(Cv::MatND->Cv::assoc('Clear'));
	ok(Cv::MatND->Cv::assoc('Clone'));
	ok(Cv::MatND->Cv::assoc('CloneMat'));

	# O-U
	ok(Cv::RNG->Cv::assoc('Arr'));
	ok(Cv::RNG->Cv::assoc('Int'));
	ok(Cv::RNG->Cv::assoc('Real'));

	ok(Cv->assoc('CreateSeq'));
	ok(Cv::Seq->Cv::assoc('new'));
	ok(Cv::Seq->Cv::assoc('Clear'));
	ok(Cv::Seq->Cv::assoc('Clone'));

	ok(Cv->assoc('CreateSparseMat'));
	ok(Cv::SparseMat->Cv::assoc('new'));
	ok(Cv::SparseMat->Cv::assoc('refcount'));
	ok(Cv::SparseMat->Cv::assoc('Clear'));
	ok(Cv::SparseMat->Cv::assoc('Clone'));
	ok(Cv::SparseMat->Cv::assoc('CloneMat'));

	ok(Cv->assoc('CreateStereoBMState'));
	ok(Cv::StereoBMState->Cv::assoc('new'));

  SKIP: {
	  skip "cvCreateStereoGCState", 2 unless Cv->can('cvCreateStereoGCState');
	  ok(Cv->assoc('CreateStereoGCState'));
	  ok(Cv::StereoGCState->Cv::assoc('new'));
	}

	# V-Z
	ok(Cv->assoc('CreateVideoWriter'));
	ok(Cv::VideoWriter->Cv::assoc('new'));
}
