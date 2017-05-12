#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv 0.19;
use File::Basename;

my $imagename = shift || dirname($0) . "/lena.jpg";
my $img = Cv->loadImage($imagename);

# check if the image has been loaded properly
die "$0: Can not load image $imagename" unless $img;

my $rng = Cv->RNG(-1);
my $noise = $img->new(CV_32FC1);
$rng->randArr($noise, CV_RAND_NORMAL, cvScalarAll(0), cvScalarAll(20));
$noise->smooth($noise, CV_GAUSSIAN, 5, 5, 1, 1);

# convert image to YUV color space. The output image will be created
# automatically, and split the image into separate color planes
my ($y, $u, $v) = $img->cvtColor(CV_BGR2YCrCb)->split;
$y->acc($noise)->convert($y);
# Cv->merge($y, $u, $v)->cvtColor(CV_YCrCb2BGR)->show($imagename);
# Cv->waitKey();

use Gtk2 -init;
my $dlg = Gtk2::Dialog->new;
my $hbox = Gtk2::HBox->new;
$dlg->vbox->add($hbox);

# my $lena = shift || dirname($0) . "/lena.jpg";
# my $frame = Gtk2::Frame->new($lena);
my $frame = Gtk2::Frame->new;

$frame->add(Cv->merge($y, $u, $v)->cvtColor(CV_YCrCb2BGR)->gtk2);
$hbox->add($frame);

$dlg->add_button('gtk-close' => 'close');
$dlg->show_all;
$dlg->run;


package Cv::Arr;

sub Gtk2 {
	my $img = shift;
	$img->cvtColor(Cv::CV_BGR2RGB)->getRawData(my $data, my $step);
	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data(
		$data,				# the data.  this will be copied.
		'rgb',				# only currently supported colorspace
		0,					# true if $data has alpha channel
		$img->depth,		# gdk-pixbuf currently allows only 8-bit samples
		$img->height,		# width in pixels
		$img->width,		# height in pixels
		$step);				# rowstride
	Gtk2::Image->new_from_pixbuf($pixbuf);
}

