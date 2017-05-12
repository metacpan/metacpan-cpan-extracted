#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Cv::Flipbook;

Cv->NamedWindow("Cv", 0);
foreach my $dir (@ARGV) {
	my $capture = Cv->CaptureFromFlipbook($dir);
	$capture or die "can't create capture";
	while (my $frame = $capture->queryFrame) {
		$frame->show("Cv");
		my $c = Cv->waitKey(100);
		$c &= 0x7f if ($c >= 0);
		last if ($c == 27);
	}
	Cv->destroyWindow($dir);
}
