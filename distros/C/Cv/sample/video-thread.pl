#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Scalar::Util qw(blessed);

use Config;
die "$0: can not use threads\n" unless $Config{useithreads};
eval 'use threads;';
eval 'use Thread::Queue;';

sub capture {
	my ($req, $cap, $cam) = @_;
	my $capture = Cv->captureFromCAM($cam);
	$capture or die "can't create capture";
	while ($req->dequeue) {
		last unless my $frame = $capture->queryFrame;
		$cap->enqueue($frame);
		bless $frame, join('::', blessed $frame, 'Ghost');
	}
	$cap->enqueue(undef);
}

Cv->namedWindow('Cv', 0);
my $fourcc = CV_FOURCC('MJPG');
my $video = Cv->createVideoWriter("sample.avi", $fourcc, 10, [ 320, 240 ]);

my $cam = 0;
my $req = Thread::Queue->new;
my $cap = Thread::Queue->new;
my $thr = threads->new(\&capture, $req, $cap, $cam);
my $more = 1;
$req->enqueue($more);

while (my $frame = $cap->dequeue) {
    $video->writeFrame($frame);
    $frame->show('Cv');
	$req->enqueue($more);
    my $c = Cv->waitKey(100);
    $c &= 0x7f if ($c >= 0);
    last if ($c == 27);
}
