# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

=encoding utf8

=head1 NAME

Cv::Pango - Draw a variety of characters using the Pango

=head1 SYNOPSIS

 use Cv;
 use Cv::Pango;
 
 my $img = Cv::Mat->new([240, 320], CV_8UC4);
 $img->putText(
	"\x{03A0}\x{03B1}\x{03BD}\x{8A9E}", # "Παν語",
	[20, 200], 'Sans Serif 42',
	);
 $img->showImage;
 $img->waitKey;

=cut

package Cv::Pango;

use 5.008008;
use strict;
use warnings;
use Carp;
use Pango;
use Cv 0.26;

our $VERSION = '0.28';

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ( );

our %EXPORT_TAGS = (
	'all' => \@EXPORT_OK,
	);

our @EXPORT = ( );

*AUTOLOAD = \&Cv::autoload;

=head1 DESCRIPTION

C<Cv::Pango> draw a variety of characters by using Pango.
Replace C<Cv::Arr::PutText()> itself.


=head2 METHOD

=over

=item PutText

  $img->putText($text, $org, $font, $color);

=cut

{ no warnings 'redefine'; sub Cv::Arr::PutText { goto &PutText } }

sub PutText {
	my ($img, $text, $org, $font, $color) = @_;
	goto &Cv::Arr::cvPutText if ref $font && $font->isa('Cv::Font');
	my $oimg = $img;
	if ($oimg->type == Cv::CV_8UC3) {
		my ($b, $g, $r) = $oimg->split;
		$img = Cv->merge([$b, $g, $r, $b->new->zero]);
	}
	my $type = $img->type;
	my $cairo_format; # argb32, rgb24, a8, a1, rgb16-565 
	$cairo_format = 'a8'     if $type == Cv::CV_8UC1;
	# $cairo_format = 'rgb24'  if $type == Cv::CV_8UC3;
	$cairo_format = 'argb32' if $type == Cv::CV_8UC4;
	goto &cvPutText unless $cairo_format;
	$img->getRawData(my $data, my $step, my $size);
	my $surface = Cairo::ImageSurface->create_for_data(
		$data, $cairo_format, @$size, $step);
	my $cr = Cairo::Context->create($surface);
	my $layout = Pango::Cairo::create_layout($cr);
	$font = Pango::FontDescription->from_string($font)
		unless ref $font;
	$layout->set_font_description($font);
	$cr->move_to($org->[0], $org->[1]);
	$layout->set_text($text);
	my $line = $layout->get_line(0);
	Pango::Cairo::layout_line_path($cr, $line);
	my @color = map { $_ / 255 } @$color;
	push(@color, (0) x (3 - @color)) if @color < 3;
	my ($b, $g, $r, $a) = @color;
	$cr->set_source_rgba($r, $g, $b, 1);
	$cr->fill_preserve;
	# $cr->stroke;
	if ($oimg->type == Cv::CV_8UC3) {
		my ($b, $g, $r, $a) = $img->split;
		Cv->merge([$b, $g, $r])->copy($oimg);
	}
	$oimg;
}


=item BoxText

  $img->boxText($text, $org, $font, $color);

=cut

{ no warnings 'redefine'; sub Cv::Arr::BoxText { goto &BoxText } }

sub BoxText {
	my ($img, $text, $org, $font, $color) = @_;
	$font = Pango::FontDescription->from_string($font)
		unless ref $font;
	Cv->GetTextSize($text, $font, my $sz, my $b);

	# A ---- D
	# |      |
	# M ---- N
	# |      |
	# B ---- C

	my @M = @$org;
	my @N = ($M[0] + $sz->[0], $M[1]);
	my @A = ($M[0], $M[1] - $sz->[1]);
	my @B = ($M[0], $M[1] + $b);
	my @C = ($N[0], $B[1]);
	my @D = ($N[0], $A[1]);
	
	$img->polyLine([ [\@A, \@B, \@C, \@D, \@A],
					 [\@M, \@N]
				   ], 0, $color, 1);
}


=item GetTextSize

  Cv->getTextSize($textString, $font, my $textSize, my $baseline);
    or
  $font->getTextSize($textString, my $textSize, my $baseline);

=cut


{ no warnings 'redefine'; sub Cv::GetTextSize { goto &GetTextSize } }

sub GetTextSize {
	my ($class, $text, $font);
	$class = shift if @_ == 5 && $_[0] =~ /^Cv/ && !ref $_[0];
	$font = shift if ref $_[0] && @_ == 4;
	$text = shift if @_ >= 3;
	$font ||= shift if @_ >= 3;
	Cv::Usage("textString, font, textSize, baseline") unless @_ == 2;
	if ($font && ref $font eq 'Cv::Font') {
		unshift(@_, $text, $font);
		goto \&cvGetTextSize;
	} elsif (!ref $font || ref $font eq 'Pango::FontDescription') {
		my $PANGO_SCALE = 1024; # see pango-1.0/pango/pango-types.h
		my $surface = Cairo::ImageSurface->create('a8', 16, 16);
		my $cr = Cairo::Context->create($surface);
		my $layout = Pango::Cairo::create_layout($cr);
		$layout->set_font_description($font);
		$layout->set_text($text);
		Pango::Cairo::layout_path($cr, $layout);
		my ($w, $hh, $bb) = map { $_ / $PANGO_SCALE } (
			$layout->get_size(),
			$layout->get_baseline()
		);
		my ($h, $b) = ($bb, -$bb + $hh);
		if (@_ >= 1) {
			$_[0] = [] unless ref $_[0] eq 'ARRAY';
			@{$_[0]} = ($w, $h);
		}
		if (@_ >= 2) {
			$_[1] = $b;
		}
	} else {
		Carp::croak "unknown font @{[ ref $_[1] ]} in Cv::Pango::GetTextSize";
	}
}

1;
__END__

=back

=head1 SEE ALSO

C<Cv>, C<Pango>

=head1 AUTHOR

MASUDA Yuta E<lt>yuta.cpan@gmail.comE<gt>

=head1 LICENCE

Copyright (c) 2013 by Masuda Yuta.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
