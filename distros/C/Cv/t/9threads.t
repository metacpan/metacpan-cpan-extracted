# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use Test::More qw(no_plan);
# use Test::More tests => 13;

BEGIN {
	use_ok('Cv', -nomore);
}

use File::Basename;
use Time::HiRes qw(usleep);
use Scalar::Util qw(blessed);
my $verbose = Cv->hasGUI;

use Config;

SKIP: {
	skip('can not use threads', 1) unless $Config{useithreads};
	skip('need OpenCV 2.0+', 1) unless cvVersion() >= 2.0;
	eval 'use threads;';
	eval 'use Thread::Queue;';

	my $sample = dirname($0) . "/../sample";
	my @imgs = grep { -f $_ } glob("$sample/*.png");

	sub sub1 {
		my $q = shift;
		foreach (@imgs) {
			my $img = Cv->LoadImage($_);
			$q->enqueue($img);
			usleep(200_000);
			bless $img, join('::', blessed $img, 'Ghost');
		}
		$q->enqueue(undef);
	}
	
	my $nr_imgs = 0;
	my $q = Thread::Queue->new;
	my $thr = threads->new(\&sub1, $q);
	while (my $img = $q->dequeue) {
		$nr_imgs++;
		ok($img->isa('Cv::Image'));
		if ($verbose) {
			$img->show;
			Cv->waitKey(100);
		}
	}
	$thr->join;
	
	ok($nr_imgs == @imgs);
}

