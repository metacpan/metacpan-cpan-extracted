# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 12;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

# ============================================================
#  cvCvtSeqToArray(const CvSeq* seq, SV* elements, CvSlice slice=CV_WHOLE_SEQ)
# ============================================================

if (1) {
	my $seq = Cv::Seq::Point->new(CV_32SC1);
	ok($seq->isa('Cv::Seq::Point'));
	$seq->push(map [$_], 0 .. 9);

	if (1.1) {
		Cv::Arr::cvCvtSeqToArray($seq, my $elements);
		my @got = unpack("i*", $elements);
		my @expect = (0 .. 9);
		is_deeply(\@got, \@expect);
		is($seq->SliceLength(CV_WHOLE_SEQ), scalar @expect);
	}

	if (1.2) {
		my $slice = cvSlice(1, 3);
		Cv::Arr::cvCvtSeqToArray($seq, my $elements, $slice);
		my @got = unpack("i*", $elements);
		my @expect = (1 .. 2);
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}

	if (1.3) {
		my $slice = cvSlice(-1, 3);
		Cv::Arr::cvCvtSeqToArray($seq, my $elements, $slice);
		my @got = unpack("i*", $elements);
		my @expect = (9, 0 .. 2);
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}

	if (1.4) {
		my $slice = cvSlice(0, -1);
		Cv::Arr::cvCvtSeqToArray($seq, my $elements, $slice);
		my @got = unpack("i*", $elements);
		my @expect = (0 .. 8);
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}

	if (1.5) {
		my $slice = cvSlice(0, 0);
		Cv::Arr::cvCvtSeqToArray($seq, my $elements, $slice);
		my @got = unpack("i*", $elements);
		my @expect = ();
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}

}
