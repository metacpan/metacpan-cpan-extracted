#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

my $filename = @ARGV > 0? shift : dirname($0).'/'."fruits.jpg";
my $img0 = Cv->loadImage($filename, 1)
    or die "$0: can't loadimage $filename\n";

print "Hot keys: \n",
    "\tESC - quit the program\n",
    "\tr - restore the original image\n",
    "\tw or SPACE - run watershed algorithm\n",
    "\t\t(before running it, roughly mark the areas on the image)\n",
    "\t  (before that, roughly outline several markers on the image)\n";

Cv->namedWindow(my $image_win = "image", 1);
Cv->namedWindow(my $watershed_win = "watershed transform", 1);

my $markers = Cv::Image->new($img0->sizes, CV_32SC1)->zero;
my $marker_mask = Cv::Image->new($markers->sizes, CV_8UC1)->zero;
my $img = $img0->clone->show($image_win);
my $wshed = $img0->clone->zero->show($watershed_win);

my $prev_pt = [ -1, -1 ];
Cv->setMouseCallback($image_win, \&on_mouse);

while (1) {
	my $c = Cv->waitKey;
	if (($c & 0xffff) == 27 || ($c & 0xffff) == ord('q')) {
		last;
	} elsif (($c & 0xffff) == ord('r')) {
		$marker_mask->zero;
		$img0->copy($img)->show($image_win);
	} elsif (($c & 0xffff) == ord('w') || ($c & 0xffff) == ord(' ')) {
		my $storage = Cv::MemStorage->new(0);
		$markers->zero;
		$marker_mask->findContours(
			$storage, my $contour, CV_SIZEOF('CvContour'),
			CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
		my $comp_count = 0;
		for ( ; $contour; $contour = $contour->h_next) {
			my $color = [ ($comp_count + 1) x 3 ]; $comp_count++;
			$markers->drawContours($contour, $color, $color, -1, -1, 8);
		}
		my $color_tab = Cv::Mat->new([256, 1], CV_8UC3)->zero;
		$color_tab->set([0], [ 80, 80, 80 ]);
		$color_tab->set([1], [ 255, 255, 255 ]);
		$color_tab->set([$_], [ map { rand(180) + 50 } 1..3 ])
			foreach (2 .. $comp_count + 1);
		my $t = Cv->GetTickCount();
		$img0->watershed($markers);
		$t = Cv->GetTickCount() - $t;
		printf("exec time = %gms\n", $t/(Cv->GetTickFrequency() * 1000.0));
		my $img_wshed = $img0->cvtColor(CV_BGR2GRAY)->cvtColor(CV_GRAY2BGR)
			->addWeighted(0.5, $markers->convertScale(
							  1, 1, $markers->new($markers->sizes, CV_8UC1)
						  )->LUT($wshed, $color_tab), 0.5, 0.0);
		$img_wshed->show($watershed_win);
	}
}


sub on_mouse {
    my ($event, $x, $y, $flags, $param) = @_;
    return unless $img;
    if ($event == CV_EVENT_LBUTTONUP || !($flags & CV_EVENT_FLAG_LBUTTON)) {
        $prev_pt = [ -1, -1 ];
    } elsif ($event == CV_EVENT_LBUTTONDOWN) {
        $prev_pt = [ $x, $y ];
    } elsif ($event == CV_EVENT_MOUSEMOVE && ($flags & CV_EVENT_FLAG_LBUTTON)) {
        my $pt = [ $x, $y ];
		$prev_pt = $pt if $prev_pt->[0] < 0;
        $marker_mask->line($prev_pt, $pt, [ 255, 255, 255 ], 5, 8, 0);
        $img->line($prev_pt, $pt, [ 255, 255, 255 ], 5, 8, 0);
		$img->show($image_win);
        $prev_pt = $pt;
    }
}
