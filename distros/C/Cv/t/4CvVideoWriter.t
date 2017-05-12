# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More qw(no_plan);
# use Test::More tests => 5;
use Test::Exception;
BEGIN { use_ok('Cv') }

SKIP: {
	my $cap = Cv->captureFromCAM(0);
	skip "can't capture #0", 3 unless $cap;
	my $frame = $cap->query;
	skip "can't query #0", 3 unless $frame;
	my $fourcc;
	for (qw(DIVX HFYU DRAC XVID X264 MP1V)) {
		my $v = eval { Cv->createVideoWriter("a.avi", $_, 30, $frame->size) };
		$fourcc = $_, last if $v && !$@;
	}
	skip "can't query #0", 3 unless $fourcc;
	my $v1 = Cv->createVideoWriter("a.avi", $fourcc, 30, $frame->size);
	isa_ok($v1, 'Cv::VideoWriter');
	my $v2 = Cv->createVideoWriter("a.avi", $fourcc, 30, $frame->size);
	isa_ok($v2, 'Cv::VideoWriter');
	my $v3 = Cv->createVideoWriter("a.avi", $fourcc, 30, $frame->size);
	isa_ok($v3, 'Cv::VideoWriter');
	unlink("a.avi");
}
