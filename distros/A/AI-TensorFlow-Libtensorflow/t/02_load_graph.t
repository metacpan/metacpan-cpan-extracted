#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;
use lib 't/lib';

use TF_TestQuiet;
use AI::TensorFlow::Libtensorflow;
use Path::Tiny;

use lib 't/lib';

subtest "Load graph" => sub {
	my $model_file = path("t/models/graph.pb");
	my $ffi = FFI::Platypus->new( api => 1 );

	my $data = $model_file->slurp_raw;
	my $buf = AI::TensorFlow::Libtensorflow::Buffer->NewFromData($data);
	ok $buf;

	my $graph = AI::TensorFlow::Libtensorflow::Graph->New;
	my $status = AI::TensorFlow::Libtensorflow::Status->New;
	my $opts = AI::TensorFlow::Libtensorflow::ImportGraphDefOptions->New;

	$graph->ImportGraphDef( $buf, $opts, $status );

	if( $status->GetCode == AI::TensorFlow::Libtensorflow::Status::OK ) {
		print "Load graph success\n";
		pass;
	} else {
		fail;
	}

	pass;
};

done_testing;
