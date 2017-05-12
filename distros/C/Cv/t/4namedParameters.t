# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More qw(no_plan);
# use Test::More tests => 24;
use Test::Exception;
BEGIN { use_ok('Cv') }

if (1) {
	my @template = (
		delta => 5,
		minArea => 60,
		maxArea => 14400,
		maxVariation => 0.25,
		minDiversity => 0.2,
		maxEvolution => 200,
		areaThreshold => 1.01,
		minMargin => 0.003,
		edgeBlurSize => 5,
		);
	my %template = @template;

	my $p = Cv::named_parameter(\@template);
	is($p->{$_}, $template{$_}, $_) for keys %template;

	my $q = Cv::named_parameter(\@template, -delta => 1);
	is($q->{delta}, 1);

	my $r = Cv::named_parameter(\@template, 1);
	is($r->{delta}, 1);
}
