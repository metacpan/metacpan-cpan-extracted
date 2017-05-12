#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use Imager;
use File::Basename;

my $lena = shift || dirname($0) . "/lena.jpg";

# load image using Imager
my $imager = Imager->new(file => $lena)
    or die Imager->errstr();

# convert Imager to Cv
$imager->write(data => \my $data, type => 'pnm')
	or die $imager->errstr;
my $img = Cv->decodeImage($data);

# show the image
$img->show;
Cv->waitKey;

# convert Cv to Imager
my $imager2 = Imager->new(data => $img->encodeImage(".ppm")->ptr);
