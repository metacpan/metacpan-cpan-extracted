#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;
use Data::Dumper;

my $filename = @ARGV > 0? shift : dirname($0).'/'."fruits.jpg";
my $img0 = Cv->LoadImage($filename, -1)
    or die "$0: can't loadimage $filename\n";

print "Hot keys: \n",
	"\tESC - quit the program\n",
	"\tr - restore the original image\n",
	"\ti or SPACE - run inpainting algorithm\n",
	"\t\t(before running it, paint something on the image)\n";
    
Cv->NamedWindow("image", 1);
Cv->SetMouseCallback("image", \&on_mouse);

my $img = $img0->Clone;
my $inpainted = $img0->Clone->Zero;
my $inpaint_mask = Cv::Image->new($img->sizes, CV_8UC1)->Zero;
$img->ShowImage("image");

while (1) {
	my $c = Cv->WaitKey;
	$c &= 0x7f if ($c >= 0);
	last if ($c == 27);
	if ($c == ord('r')) {
		$inpaint_mask->Zero;
		$img0->Copy($img);
		$img->ShowImage("image");
	}
	if ($c == ord('i') || $c == ord(' ')) {
		Cv->NamedWindow("inpainted image", 1);
		$img->Inpaint($inpaint_mask, $inpainted, 3, CV_INPAINT_TELEA);
		$inpainted->ShowImage("inpainted image");
	}
}

my $prev_pt = [-1, -1];

sub on_mouse {
	my ($event, $x, $y, $flags, $param) = @_;
    return unless $img;
    if ($event == CV_EVENT_LBUTTONUP || !($flags & CV_EVENT_FLAG_LBUTTON)) {
        $prev_pt = [-1, -1];
	} elsif ($event == CV_EVENT_LBUTTONDOWN) {
        $prev_pt = [$x, $y];
	} elsif ($event == CV_EVENT_MOUSEMOVE && ($flags & CV_EVENT_FLAG_LBUTTON)) {
        my $pt = [$x, $y];
        $prev_pt = $pt if ($prev_pt->[0] < 0);
		for ($inpaint_mask, $img) {
			$_->Line($prev_pt, $pt, CV_RGB(255, 255, 255), 5, 8, 0);
		}
        $prev_pt = $pt;
        $img->ShowImage("image");
    }
}

