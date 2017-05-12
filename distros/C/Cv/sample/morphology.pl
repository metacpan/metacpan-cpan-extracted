#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

my $element_shape = CV_SHAPE_RECT;

# the address of variable which receives trackbar position update 
my $max_iters = 10;

my $filename = @ARGV > 0? shift : dirname($0).'/'."baboon.jpg";
my $src = Cv->LoadImage($filename, 1)
    or die "$0: can't loadimage $filename\n";

print STDERR "Hot keys: \n",
    "\tESC - quit the program\n",
    "\tr - use rectangle structuring element\n",
    "\te - use elliptic structuring element\n",
    "\tc - use cross-shaped structuring element\n",
    "\tSPACE - loop through all the options\n";

# create windows for output images
my $oc_win = "Open/Close";
my $ed_win = "Erode/Dilate";
Cv->NamedWindow($oc_win, 1);
Cv->NamedWindow($ed_win, 1);

Cv->CreateTrackbar("iterations", $oc_win, my $oc_pos = $max_iters,
				   $max_iters*2 + 1, \&OpenClose);
Cv->CreateTrackbar("iterations", $ed_win, my $ed_pos = 10,
				   $max_iters*2 + 1,  \&ErodeDilate);

while (1) {
    &OpenClose;
    &ErodeDilate;
    my $c = Cv->WaitKey;
    if (($c & 0x7f) == 27) {
		last;
    } elsif (($c & 0x7f) == ord('e')) {
		$element_shape = CV_SHAPE_ELLIPSE;
    } elsif (($c & 0x7f) == ord('r')) {
		$element_shape = CV_SHAPE_RECT;
    } elsif (($c & 0x7f) == ord('c')) {
		$element_shape = CV_SHAPE_CROSS;
    } elsif (($c & 0x7f) == ord(' ')) {
		$element_shape = ($element_shape + 1) % 3;
    }
}

exit 0;


# callback function for open/close trackbar
sub OpenClose {
    my $n = $oc_pos - $max_iters;
    my $an = abs($n);
    my $element = Cv::ConvKernel->new(
		$an*2 + 1, $an*2 + 1, $an, $an, $element_shape
		);

    my $dst = ($n < 0)
		? $src->Erode($element)->Dilate($element)
		: $src->Dilate($element)->Erode($element);
    $dst->ShowImage($oc_win);
}


# callback function for erode/dilate trackbar
sub ErodeDilate {
    my $n = $ed_pos - $max_iters;
    my $an = abs($n);
    my $element = Cv::ConvKernel->new(
		$an*2 + 1, $an*2 + 1, $an, $an, $element_shape
		);
	
	my $dst = ($n < 0)
		? $src->Erode($element)
		: $src->Dilate($element);
    $dst->ShowImage($ed_win);
}   
