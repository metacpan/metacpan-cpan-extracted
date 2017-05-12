# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use Test::More qw(no_plan);
# use Test::More tests => 10;

BEGIN {
	use_ok('Cv', -nomore);
	use_ok('Cv::Flipbook');
}

use File::Basename;
use List::Util qw(min max);
my $verbose = Cv->hasGUI;

my $font = Cv->InitFont(CV_FONT_HERSHEY_PLAIN, 1.0, 1.0, 0, 2, CV_AA);
if ($verbose) {
	Cv->namedWindow('movie', 1);
}
SKIP: {
	my $flipbook = dirname($0) . "/flipbook/";
	skip("flipbook not found", 1) unless -d $flipbook;

	#my $cap1 = eval { Cv->captureFromFlipbook() };
	#is($cap1, undef);
	my $cap2 = eval { Cv->captureFromFlipbook("/path/not/to/exist") };
	is($cap2, undef);
	my $cap3 = eval { Cv->captureFromFlipbook($flipbook, undef, ".xxx") };
	is($cap3, undef);
	my $cap4 = eval { Cv->captureFromFlipbook($flipbook, undef, "*.png") };
	ok($cap4);
	ok($cap4->getProperty(CV_CAP_PROP_FRAME_COUNT));
	undef $cap4;

	my $capture = eval { Cv->captureFromFlipbook(
		$flipbook, CV_LOAD_IMAGE_GRAYSCALE, [ qq(*.png) ]
		) };
	is($capture->{flags}, CV_LOAD_IMAGE_GRAYSCALE);
	$capture->setProperty(CV_CAP_PROP_FPS, 1 / (12 * 3600));

	$capture->setProperty(
		CV_CAP_PROP_POS_FRAMES,
		max($capture->getProperty(CV_CAP_PROP_FRAME_COUNT) - 30, 0)
		);

	my $lastimg; my $quit = 0;
  movie:
	while (my $frame = $capture->queryFrame) {
		my $img = $frame->cvtColor(CV_GRAY2RGB);
		my $pos_frames = $capture->getProperty(CV_CAP_PROP_POS_FRAMES);
		$img->putText(sprintf("CAP_PROP_POS_FRAMES: %d", $pos_frames),
					  [ 30, $frame->height - 30 ], $font, [ 255, 128, 128 ]);
		my $pos_msec = $capture->getProperty(CV_CAP_PROP_POS_MSEC);
		$img->putText(sprintf("CAP_PROP_POS_MSEC: %.1fmsec", $pos_msec * 1e-3),
					  [ 30, $frame->height - 50 ], $font, [ 255, 128, 128 ]);
		$img->putText(sprintf("file: %s", basename($capture->{file})),
					  [ 30, $frame->height - 70 ], $font, [ 255, 128, 128 ]);
		if ($lastimg) {
			foreach my $alpha (1/3, 2/3, 1) {
				my $beta = 1.0 - $alpha; my $gamma = 0;
				my $added = $img->addWeighted($alpha, $lastimg, $beta, $gamma,
											  $img->new);
				if ($verbose) {
					$added->show('movie');
					my $c = Cv->waitKey(100);
					if ($c > 0 && ($c & 0xff) == 27) {
						$quit = 1;
						last movie;
					}
				}
			}
		} else {
			if ($verbose) {
				$img->show('movie');
				my $c = Cv->waitKey(300);
				if ($c > 0 && ($c & 0xff) == 27) {
					$quit = 1;
					last movie;
				}
			}
		}
		$lastimg = $img;
	}
	ok($quit || !$capture->grabFrame);
	ok($quit || !$capture->retrieveFrame);
}
if ($verbose) {
	Cv->waitKey(3000);
}
