#!/usr/bin/env perl

use Test2::V0;
use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;
use aliased 'AI::TensorFlow::Libtensorflow';
use Path::Tiny;

## From tensorflow/cc/saved_model/tag_constants.h
my %saved_model_tags = (
	GPU     => "gpu",
	TPU     => "tpu",
	SERVE   => "serve",
	TRAIN   => "train",
);

subtest "(CAPI, SavedModel)" => sub {
	note 'Load the saved model.';
	my $saved_model_dir = path(
		qw(t upstream),
		"tensorflow", "cc", "saved_model", "testdata",
                               "half_plus_two", "00000123"
	);
	my $opt = AI::TensorFlow::Libtensorflow::SessionOptions->New;
	my $run_options_str = "";
	my $run_options = AI::TensorFlow::Libtensorflow::Buffer->NewFromString( \$run_options_str );
	my $metagraph = AI::TensorFlow::Libtensorflow::Buffer->New;
	my $s = AI::TensorFlow::Libtensorflow::Status->New;
	my @tags = ( $saved_model_tags{SERVE} );
	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;
	my $session = AI::TensorFlow::Libtensorflow::Session->LoadFromSavedModel(
		$opt, $run_options, "$saved_model_dir", \@tags, $graph, $metagraph, $s
	);
	pass 'Skipping. Can not use C++ tensorflow::MetaGraphDef.';

	TF_Utils::AssertStatusOK($s);
	my $csession = TF_Utils::CSession->new( session => $session, status => $s );

	pass 'Skipping getting signature_def.';

	pass 'Skipping writing tensorflow::Example';

	pass 'Skipping setting inputs';

	pass 'Skipping setting outputs';

	pass 'Skipping running session';
};

done_testing;
