#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;

my $filename = @ARGV > 0 ? shift : dirname($0).'/'."lena.jpg";
my $im = Cv->LoadImage($filename, CV_LOAD_IMAGE_GRAYSCALE) or 
	die "Image was not loaded.\n";

my $realInput      = Cv::Image->new($im->sizes, CV_64FC1);
my $imaginaryInput = Cv::Image->new($im->sizes, CV_64FC1)->Zero;
my $complexInput   = Cv::Image->new($im->sizes, CV_64FC2);

$im->Scale($realInput, 1.0, 0.0);
Cv->Merge([$realInput, $imaginaryInput], $complexInput);

my $dft_M = Cv->GetOptimalDFTSize($im->height - 1);
my $dft_N = Cv->GetOptimalDFTSize($im->width  - 1);
my $dft_A = Cv::Mat->new([$dft_M, $dft_N], CV_64FC2);

my $image_Re = Cv::Image->new([$dft_M, $dft_N], CV_64FC1);
my $image_Im = Cv::Image->new([$dft_M, $dft_N], CV_64FC1);

# copy A to dft_A and pad dft_A with zeros
my $tmp = $complexInput->Copy(
	$dft_A->GetSubRect([0, 0, $im->width, $im->height])
	);
if ($dft_A->cols > $im->width) {
	$dft_A->GetSubRect(
		$tmp, [ $im->width, 0, $dft_A->cols - $im->width, $im->height ]
		);
	$tmp->Zero;
}

# no need to pad bottom part of dft_A with zeros because of
# use nonzero_rows parameter in cvDFT() call below
$dft_A = $dft_A->DFT(CV_DXT_FORWARD, $complexInput->height);

$im->ShowImage("win");

# Split Fourier in real and imaginary parts
$dft_A->Split($image_Re, $image_Im);

# Compute the magnitude of the spectrum Mag = sqrt(Re^2 + Im^2)
$image_Re =
	Cv::Arr::Add($image_Re->Pow(2), $image_Im->Pow(2))
	->Pow(0.5)
# Compute log(1 + Mag)
	->Add(cvScalarAll(1.0))
	->Log;


# Rearrange the quadrants of Fourier image so that the origin is at
# the image center
&cvShiftDFT;

$image_Re->MinMaxLoc(my $min, my $max, my $min_loc, my $max_loc);
if (my $d = $max - $min) {
	$image_Re =	$image_Re->Scale(1 / $d, -$min / $d);
}
$image_Re->ShowImage("magnitude");

Cv->WaitKey;
exit 0;

# Rearrange the quadrants of Fourier image so that the origin is at
# the image center
# src & dst arrays of equal size & type
sub cvShiftDFT {
	my $src = $image_Re;
	my $dst = $image_Re;

    if ($dst->width  != $src->width ||
		$dst->height != $src->height){
        Cv->cvError(CV_StsUnmatchedSizes, "cvShiftDFT",
					"Source and Destination arrays must have equal sizes",
					__FILE__, __LINE__,
			);
    }

    my $cx = $src->width/2;
    my $cy = $src->height/2; # image center
	my $type = $src->GetElemType;
	
	my $tmp = Cv::Mat->new([ $cy, $cx], $type);
	my $q1  = Cv::Mat->new([ $cy, $cx], $type, undef);
	my $q2  = Cv::Mat->new([ $cy, $cx], $type, undef);
	my $q3  = Cv::Mat->new([ $cy, $cx], $type, undef);
	my $q4  = Cv::Mat->new([ $cy, $cx], $type, undef);
	my $d1  = Cv::Mat->new([ $cy, $cx], $type, undef);
	my $d2  = Cv::Mat->new([ $cy, $cx], $type, undef);
	my $d3  = Cv::Mat->new([ $cy, $cx], $type, undef);
	my $d4  = Cv::Mat->new([ $cy, $cx], $type, undef);

	$src->GetSubRect($q1, [0,     0, $cx, $cy]);
	$src->GetSubRect($q2, [$cx,   0, $cx, $cy]);
	$src->GetSubRect($q3, [$cx, $cy, $cx, $cy]);
	$src->GetSubRect($q4, [0,   $cy, $cx, $cy]);
	$src->GetSubRect($d1, [0,     0, $cx, $cy]);
	$src->GetSubRect($d2, [$cx,   0, $cx, $cy]);
	$src->GetSubRect($d3, [$cx, $cy, $cx, $cy]);
	$src->GetSubRect($d4, [0,   $cy, $cx, $cy]);

    if ($src != $dst) {
        unless ($q1->type == $d1->type) {
            Cv->cvError(
				CV_StsUnmatchedFormats, "cvShiftDFT",
				"Source and Destination arrays must have the same format",
				__FILE__, __LINE__
				);
        }
        $q3->Copy($d1);
        $q4->Copy($d2);
        $q1->Copy($d3);
        $q2->Copy($d4);
    } else {
        $q3->Copy($tmp);
        $q1->Copy($q3);
        $tmp->Copy($q1);
        $q4->Copy($tmp);
        $q2->Copy($q4);
        $tmp->Copy($q2);
    }
}
