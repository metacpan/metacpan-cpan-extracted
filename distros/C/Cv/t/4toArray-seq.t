# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 17;
use Test::Exception;
BEGIN { use_ok('Cv') }

if (1) {
	my $seq = Cv::Seq::Point->new(CV_32SC1);
	ok($seq->isa('Cv::Seq::Point'));
	my @pts = map [$_], 0 .. 9;
	$seq->push(@pts);

	if (1.1) {
		my @got = $seq->toArray;
		my @expect = @pts[0 .. 9];
		is_deeply(\@got, \@expect);
		is($seq->SliceLength(CV_WHOLE_SEQ), scalar @expect);
	}

	if (1.2) {
		my $slice = cvSlice(1, 3);
		my @got = $seq->toArray($slice);
		my @expect = @pts[1 .. 2];
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}

	if (1.3) {
		my $slice = cvSlice(-1, 3);
		my @got = $seq->toArray($slice);
		my @expect = @pts[9, 0 .. 2];
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}

	if (1.4) {
		my $slice = cvSlice(0, -1);
		my @got = $seq->toArray($slice);
		my @expect = @pts[0 .. 8];
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}

	if (1.5) {
		my $slice = cvSlice(1, 1);
		my @got = $seq->toArray($slice);
		my @expect = ();
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}
}

if (2) {
	my $seq = Cv::Seq::Point->new(CV_32SC1);
	ok($seq->isa('Cv::Seq::Point'));
	my @pts = map [$_], 0 .. 9;
	$seq->push(@pts);

	if (2.1) {
		$seq->toArray(\my @got);
		my @expect = @pts[0 .. 9];
		is_deeply(\@got, \@expect);
		is($seq->SliceLength(CV_WHOLE_SEQ), scalar @expect);
	}

	if (2.2) {
		my $slice = cvSlice(1, 3);
		$seq->toArray(\my @got, $slice);
		my @expect = @pts[1 .. 2];
		is_deeply(\@got, \@expect);
		is($seq->SliceLength($slice), scalar @expect);
	}
}
