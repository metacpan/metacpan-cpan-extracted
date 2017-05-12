# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
BEGIN {
	eval "use Pango";
	plan skip_all => "Pango required" if $@;
	plan qw(no_plan);
}

BEGIN {
	use_ok('Cv', -nomore);
	use_ok('Cv::Pango');
}

my $verbose = Cv->hasGUI;

for my $type (CV_8UC1, CV_8UC3, CV_8UC4) {
	my $img = Cv::Mat->new([240, 320], $type)->zero;
	if (1) {
		my ($text, $org, $font) = (
			"hello, world", [20, 50],
			Cv->InitFont(CV_FONT_HERSHEY_SIMPLEX, 1.0, 1.0, 0, 2, CV_AA),
			);
		$img->boxText($text, $org, $font, cvScalarAll(100 + rand 100));
		$img->putText($text, $org, $font, cvScalar(map { rand 255 } 1..3));
	}
	
	if (2) {
		my ($text, $org, $font) = (
			"hello, world", [20, 100],
			Pango::FontDescription->from_string('Sans Serif 22.5'),
			);
		$img->boxText($text, $org, $font, cvScalarAll(100 + rand 100));
		$img->putText($text, $org, $font, cvScalar(map { rand 255 } 1..3));
	}
	
	if (3) {
		my ($text, $org, $font) = (
			"\x{03A0}\x{03B1}\x{03BD}\x{8A9E}", # "Παν語",
			# 'こんにちは',
			[20, 200],
			'Sans Serif 42',
			);
		$img->boxText($text, $org, $font, cvScalarAll(100 + rand 100));
		$img->putText($text, $org, $font, cvScalar(map { rand 255 } 1..3));
	}
	
	if ($verbose) {
		$img->show("Font");
		Cv->waitKey(1000);
	}
}
