# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More tests => 20;
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my $verbose = Cv->hasGUI;

sub COLOR { cvScalar(map { rand 255 } 1..3) }

for my $type (CV_8UC1, CV_8SC1, CV_8UC3, CV_8SC3, CV_8UC4, CV_8SC4) {
	my $img = Cv::Mat->new([240, 320], $type)->zero;
	my ($text, $org, $font) = (
		"hello, world", [20, 50],
		Cv->InitFont(CV_FONT_HERSHEY_SIMPLEX, 1.0, 1.0, 0, 2, CV_AA),
		);
	lives_ok(
		sub { $img->PutText($text, $org, $font, &COLOR) },
		'Cv::Arr::PutText'
		);
	lives_ok(
		sub { Cv->GetTextSize($text, $font, my $size, my $base) },
		'Cv::GetTextSize',
		);
	lives_ok(
		sub { $font->GetTextSize($text, my $size, my $base) },
		'Cv::Font::GetTextSize',
		);
	if ($verbose) {
		$img->show("Font");
		Cv->waitKey(1000);
	}
}

if (10) {
	throws_ok(
		sub { Cv->GetTextSize() },
		qr/Usage: Cv::GetTextSize\(textString, font, textSize, baseline\)/,
		);
}
