#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

use strict;
use warnings;
use utf8;
use lib qw(blib/lib blib/arch);
use Cv;
use Pango;
# use Gtk2::Pango;
my $pango_scale = 1024;
# print $pango_scale, "\n";
# my $img = Cv->createImage([273, 47], 8, 1);
my $img = Cv->createImage([320, 240], 8, 1);
$img->getRawData(my $data, my $step, my $size);
# my $surface = Cairo::ImageSurface->create('a8', 500, 100);
my $surface = Cairo::ImageSurface->create_for_data(
	$data, 'a8', @$size, $step
	);
my $cr = Cairo::Context->create($surface);
my $layout = Pango::Cairo::create_layout($cr);
# $layout->set_text("\x{03A0}\x{03B1}\x{03BD}\x{8A9E}");
# $layout->set_text("Παν語");
$layout->set_text("こんにちは、世界");
# $layout->set_text(" fix it");
# $layout->set_text("hello, world");
# my $font = Pango::FontDescription->from_string('Sans Serif Bold 16');
# my $font = Pango::FontDescription->from_string('Vera 55');
# my $font = Pango::FontDescription->from_string('Inconsolata 55');
# my $font = Pango::FontDescription->from_string('Sazanami Mincho 55');
my $font = Pango::FontDescription->from_string('Sans Serif 32');
$layout->set_font_description($font);

my ($width, $height) = map { $_ / $pango_scale } $layout -> get_size();
#print "$width, $height\n";
if (0) {
	Pango::Cairo::show_layout($cr, $layout);
} elsif (1) {
	Pango::Cairo::layout_path($cr, $layout);
	# $cr->set_source_rgba (0.3, 0.3, 1.0, 0.3);
	$cr->set_source_rgba (0.3, 0.3, 0.3, 1.0);
	$cr->fill_preserve;
	# $cr->set_source_rgb (0.1, 0.1, 0.1);
	# $cr->stroke;
} else {
	$cr->move_to(0, $height);
	my $line = $layout->get_line(0);
	Pango::Cairo::layout_line_path($cr, $line);
	# $cr->set_source_rgba (0.3, 0.3, 1.0, 0.3);
	$cr->set_source_rgba (0.3, 0.3, 0.3, 1.0);
	$cr->fill_preserve;
	# $cr->set_source_rgb (0.1, 0.1, 0.1);
	# $cr->stroke;
}

$img->show;
# $img->save('pango.png');
Cv->waitKey;
