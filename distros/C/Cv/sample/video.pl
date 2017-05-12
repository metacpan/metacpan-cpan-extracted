#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

Cv->namedWindow('Cv', 0);
my $cap = Cv->captureFromCAM(0);
# my $fourcc = CV_FOURCC('MJPG');
# my $fourcc = CV_FOURCC("MP42");
# my $fourcc = CV_FOURCC("U263");
# my $fourcc = CV_FOURCC("FLV1");
my $fourcc = CV_FOURCC("DIVX");
my ($w, $h) = (320, 240);
my $video = Cv->createVideoWriter("sample.avi", $fourcc, 10, [$w, $h]);
while (my $frame = $cap->query) {
    $frame->flip(\0, 1)->show('Cv');
    my $c = Cv->waitKey(100);
    $c &= 0x7f if ($c >= 0);
    last if ($c == 27);
    $video->writeFrame($frame->resize([$h, $w]));
}
