#!/usr/bin/env perl

use Test::More tests => 1;

use strict;
use warnings;

use lib 't/lib';
use TF_TestQuiet;
use TF_Utils;

use AI::TensorFlow::Libtensorflow;
use PDL;

subtest "Create a TFTensor" => sub {
	my $p_data = sequence(float, 1, 5, 12);
	my $t = TF_Utils::FloatPDLToTFTensor($p_data);

	is $t->NumDims, 3, '3D TFTensor';

	is $t->Dim(0), 1 , 'dim[0] = 1';
	is $t->Dim(1), 5 , 'dim[1] = 5';
	is $t->Dim(2), 12, 'dim[2] = 12';

	pass;
};

done_testing;
