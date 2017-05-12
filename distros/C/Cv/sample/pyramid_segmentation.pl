#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use Cv;
use File::Basename;
use Data::Dumper;

my $level = 4;
my $src = undef;
my $seg = undef;

my $filename = @ARGV > 0? shift : dirname($0).'/'."fruits.jpg";
my $image = Cv->LoadImage($filename, 1)
    or die "$0: can't loadimage $filename\n";

$image->roi([ 0, 0, map { $_ & -(1 << $level) } @{$image->size} ]);

Cv->NamedWindow("Source", 0);
Cv->NamedWindow("Segmentation", 0);

$src = $image->Clone;
$src->ShowImage("Source");
$seg = $image->Clone;

# segmentation of the color image
my ($threshold1, $threshold2) = (255, 30);
my $block_size = 1000;
my $storage = Cv::MemStorage->new($block_size);

sub on_segment {
    $src->PyrSegmentation(
		$seg, $storage, my $comp, $level, $threshold1 + 1, $threshold2 + 1,
		);
    $seg->ShowImage("Segmentation");
}

Cv->CreateTrackbar(
	"Threshold1", "Segmentation", $threshold1, 255, \&on_segment,
	);
Cv->CreateTrackbar(
	"Threshold2", "Segmentation", $threshold2, 255, \&on_segment,
	);

$seg->ShowImage("Segmentation");

&on_segment;

Cv->WaitKey(0);
