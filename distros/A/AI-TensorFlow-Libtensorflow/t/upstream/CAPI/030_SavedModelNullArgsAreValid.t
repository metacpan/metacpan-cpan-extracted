#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use Path::Tiny;

subtest "(CAPI, SavedModelNullArgsAreValid)" => sub {
	my $saved_model_dir = path(
		qw(t upstream),
		"tensorflow", "cc", "saved_model", "testdata",
			"half_plus_two", "00000123"
	);
	my $opt = AI::TensorFlow::Libtensorflow::SessionOptions->New;
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my @tags = ('serve');
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;

	note 'NULL run_options and meta_graph_def should work.';
	is my $session = AI::TensorFlow::Libtensorflow::Session->LoadFromSavedModel(
		$opt, undef, "$saved_model_dir", \@tags, $graph, undef, $s
	), D();
	TF_Utils::AssertStatusOK($s);
	$session->Close($s);
	TF_Utils::AssertStatusOK($s);
	undef $session;
};

done_testing;
