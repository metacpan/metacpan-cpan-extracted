#!/usr/bin/env perl

use Test2::V0;
use aliased 'AI::TensorFlow::Libtensorflow' => 'tf';
use aliased 'AI::TensorFlow::Libtensorflow::Status';

subtest "(CAPI, Status)" => sub {
	my $s = Status->New;
	is $s->GetCode, 'OK', 'OK code';
	is $s->Message, '', 'empty message';

	note 'Set status to CANCELLED';
	$s->SetStatus('CANCELLED', 'cancel');

	is $s->GetCode, 'CANCELLED', 'CANCELLED code';
	is $s->Message, 'cancel', 'check set message';
};

done_testing;
