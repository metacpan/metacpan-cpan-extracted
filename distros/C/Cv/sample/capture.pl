#!/usr/bin/perl

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;

my $capture;
my $videoSource;
if (@ARGV == 0) {
    $capture = Cv::Capture->fromCAM(0);
    $videoSource = 0;
} elsif (@ARGV == 1 && $ARGV[0] =~ /^\d$/) {
    $capture = Cv::Capture->fromCAM($ARGV[0]);
    $videoSource = $ARGV[0];
} else {
    $capture = Cv::Capture->fromFile($ARGV[0]);
    $videoSource = $ARGV[0];
}
$capture or die "can't create capture";

Cv->namedWindow($videoSource, CV_WINDOW_NORMAL);
while (my $frame = $capture->queryFrame) {
    $frame->flip(\0, 1)->show($videoSource);
    my $c = Cv->waitKey(33);
    $c &= 0x7f if ($c >= 0);
    last if ($c == 27);
}
