# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
	eval "use Pango";
	plan skip_all => "Pango required" if $@;
	# plan qw(no_plan);
	plan tests => 33;
}

BEGIN {
	use_ok('Cv');
	use_ok('Cv::Pango')
}

my $verbose = Cv->hasGUI;

sub COLOR { cvScalar(map { rand 255 } 1..3) }

my @font = (
	Cv->InitFont(CV_FONT_HERSHEY_SIMPLEX, 1.0, 1.0, 0, 2, CV_AA),
	Pango::FontDescription->from_string('Sans Serif 22.5'),
	);

for ( (map { +{ type => CV_8UC1, font => $_ } } @font),
	  (map { +{ type => CV_8UC3, font => $_ } } @font),
	  (map { +{ type => CV_8UC4, font => $_ } } @font),
	) {
	my ($type, $font) = ($_->{type}, $_->{font});
	my $img = Cv::Mat->new([240, 320], $type)->zero;
	my ($text, $org) = ("hello, world", [20, 50]);
	lives_ok(
		sub { $img->PutText($text, $org, $font, &COLOR) },
		'Cv::Arr::PutText'
		);
	lives_ok(
		sub { Cv->GetTextSize($text, $font, my $size, my $base) },
		'Cv->GetTextSize',
		);
	if (ref $font eq 'Cv::Font') {
		lives_ok(
			sub { $font->GetTextSize($text, my $size, my $base) },
			'$font->GetTextSize',
			);
	} elsif (ref $font eq 'Pango::FontDescription') {
		throws_ok(
			sub { $font->GetTextSize($text, my $size, my $base) },
			qr/Can't locate object method "GetTextSize"/,
			);
	}
	lives_ok(
		sub { $font->Cv::Pango::GetTextSize($text, my $size, my $base) },
		'$font->Cv::Pango::GetTextSize',
		);
	lives_ok(
		sub { $font->Cv::Font::GetTextSize($text, my $size, my $base) },
		'$font->Cv::Font::GetTextSize',
		);
	if ($verbose) {
		$img->show("Font");
		Cv->waitKey(1000);
	}
}

if (10) {
	throws_ok(
		sub { Cv->GetTextSize() },
		qr/Usage: Cv::Pango::GetTextSize\(textString, font, textSize, baseline\)/,
		);
}
