# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 5;
use Test::Exception;
BEGIN { use_ok('Cv') }

my $verbose = Cv->hasGUI;

if (1) {
	my $vector = Cv->createMat(1, 3, CV_32SC2);
	$vector->set([0, 0], [100, 100]);
	$vector->set([0, 1], [150, 200]);
	$vector->set([0, 2], [200, 100]);

	my $img = Cv->createImage([300, 300], 8, 3);
	$img->zero;
	$img->origin(1);

	my $seq = $vector->pointSeqFromMat(
		CV_SEQ_KIND_GENERIC, my $header, my $block,
		);
	# use Data::Dumper;
	# print STDERR Data::Dumper->Dump([$seq], [qw(*seq)]);
	$img->polyLine([[@$seq]], -1, [0, 0, 255], 3);

	my $sorted_arr = [sort {$a->[0] <=> $b->[0]} @$seq];
	is($sorted_arr->[0]->[0], 100);
	is($sorted_arr->[0]->[1], 100);

	if ($verbose) {
		$img->show;
		Cv->waitKey(1000);
	}
}

if (2) {
	my $vector = Cv->createMat(1, 3, CV_32FC2);
	$vector->set([0, 0], [100.5, 200.5]);
	$vector->set([0, 1], [150.5, 100.5]);
	$vector->set([0, 2], [200.5, 200.5]);

	my $img = Cv->createImage([300, 300], 8, 3);
	$img->zero;
	$img->origin(1);

	my $seq = $vector->PointSeqFromMat(
		CV_SEQ_KIND_GENERIC, my $header, my $block,
		);
	$img->polyLine([[@$seq]], -1, [0, 0, 255], 3);

	my $sorted_arr = [sort {$a->[0] <=> $b->[0]} @$seq];
	is($sorted_arr->[0]->[0], 100.5);
	is($sorted_arr->[0]->[1], 200.5);

	if ($verbose) {
		$img->show;
		Cv->waitKey(1000);
	}
}
