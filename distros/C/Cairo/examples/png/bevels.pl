#!/usr/bin/perl

# This simple demo demonstrates how cairo may be used to draw
# old-fashioned widgets with bevels that depend on lines exactly
# 1-pixel wide.
#
# This demo is really only intended to demonstrate how someone might
# emulate antique graphics, and this style is really not recommended
# for future code. Some notes:
#
# 1) We're not going for pixel-perfect emulation of crusty graphics
#    here. Notice that the checkmark is rendered nicely by cairo
#    without jaggies.
#
# 2) The use of opaque highlight/lowlight colors here is particularly
#    passe. A much more interesting approach would blend translucent
#    colors over an arbitrary background.
#
# 3) This widget style is optimized for device-pixels. As such, it
#    won't scale up very well, (except for integer scale
#    factors). I'd be more interested to see future widget schemes
#    that look good at all scales.
#
# One way to get better-looking graphics at all scales might be to
# introduce some device-pixel snapping into cairo for
# horizontal/vertical path components. Then, a lot of the 0.5
# adjustments could disappear from code like this, and then this code
# could become more scalable.

use strict;
use warnings;
use Cairo;

use constant
{
	WIDTH => 100,
	HEIGHT => 70,
	M_PI => 4 * atan2(1, 1),
};

my $BG_COLOR =  [ 0xd4, 0xd0, 0xc8 ];
my $HI_COLOR_1 = [ 0xff, 0xff, 0xff ];
my $HI_COLOR_2 = [ 0xd4, 0xd0, 0xc8 ];
my $LO_COLOR_1 = [ 0x80, 0x80, 0x80 ];
my $LO_COLOR_2 = [ 0x40, 0x40, 0x40 ];
my $BLACK  = [ 0, 0, 0 ];

sub set_hex_color
{
	my ($cr, $color) = @_;
	$cr->set_source_rgb (
		$color->[0] / 255.0,
		$color->[1] / 255.0,
		$color->[2] / 255.0);
}

sub bevel_box
{
	my ($cr, $x, $y, $width, $height) = @_;

	$cr->save;

	$cr->set_line_width (1.0);
	$cr->set_line_cap ('square');

	# Fill and highlight
	set_hex_color ($cr, $HI_COLOR_1);
	$cr->rectangle ($x, $y, $width, $height);
	$cr->fill;

	# 2nd hightlight
	set_hex_color ($cr, $HI_COLOR_2);
	$cr->move_to ($x + 1.5, $y + $height - 1.5);
	$cr->rel_line_to ($width - 3, 0);
	$cr->rel_line_to (0, - ($height - 3));
	$cr->stroke;

	# 1st lowlight
	set_hex_color ($cr, $LO_COLOR_1);
	$cr->move_to ($x + 0.5, $y + $height - 1.5);
	$cr->rel_line_to (0, - ($height - 2));
	$cr->rel_line_to ($width - 2, 0);
	$cr->stroke;

	# 2nd lowlight
	set_hex_color ($cr, $LO_COLOR_2);
	$cr->move_to ($x + 1.5, $y + $height - 2.5);
	$cr->rel_line_to (0, - ($height - 4));
	$cr->rel_line_to ($width - 4, 0);
	$cr->stroke;

	$cr->restore;
}

sub bevel_circle
{
	my ($cr, $x, $y, $width) = @_;

	my $radius = ($width - 1)/2.0 - 0.5;

	$cr->save;

	$cr->set_line_width (1);

	# Fill and highlight
	set_hex_color ($cr, $HI_COLOR_1);
	$cr->arc ($x+$radius+1.5, $y+$radius+1.5, $radius, 0, 2*M_PI);
	$cr->fill;

	# 2nd highlight
	set_hex_color ($cr, $HI_COLOR_2);
	$cr->arc ($x+$radius+0.5, $y+$radius+0.5, $radius, 0, 2*M_PI);
	$cr->stroke;

	# 1st lowlight
	set_hex_color ($cr, $LO_COLOR_1);
	$cr->arc ($x+$radius+0.5, $y+$radius+0.5, $radius, 3*M_PI/4, 7*M_PI/4);
	$cr->stroke;

	# 2nd lowlight
	set_hex_color ($cr, $LO_COLOR_2);
	$cr->arc ($x+$radius+1.5, $y+$radius+1.5, $radius, 3*M_PI/4, 7*M_PI/4);
	$cr->stroke;

	$cr->restore;
}

# Slightly smaller than specified to match interior size of bevel_box
sub flat_box
{
	my ($cr, $x, $y, $width, $height) = @_;

	$cr->save;

	# Fill background
	set_hex_color ($cr, $HI_COLOR_1);
	$cr->rectangle ($x+1, $y+1, $width-2, $height-2);
	$cr->fill;

	# Stroke outline
	$cr->set_line_width (1.0);
	set_hex_color ($cr, $BLACK);
	$cr->rectangle ($x+1.5, $y+1.5, $width-3, $height-3);
	$cr->stroke;

	$cr->restore;
}

sub flat_circle
{
	my ($cr, $x, $y, $width) = @_;
	my $radius = ($width - 1) / 2.0;

	$cr->save;

	# Fill background
	set_hex_color ($cr, $HI_COLOR_1);
	$cr->arc ($x+$radius+0.5, $y+$radius+0.5, $radius-1, 0, 2*M_PI);
	$cr->fill;

	# Stroke outline
	$cr->set_line_width (1.0);
	set_hex_color ($cr, $BLACK);
	$cr->arc ($x+$radius+0.5, $y+$radius+0.5, $radius-1, 0, 2*M_PI);
	$cr->stroke;

	$cr->restore;
}

sub groovy_box
{
	my ($cr, $x, $y, $width, $height) = @_;

	$cr->save;

	# Highlight
	set_hex_color ($cr, $HI_COLOR_1);
	$cr->set_line_width (2);
	$cr->rectangle ($x+1, $y+1, $width-2, $height-2);
	$cr->stroke;

	# Lowlight
	set_hex_color ($cr, $LO_COLOR_1);
	$cr->set_line_width (1);
	$cr->rectangle ($x+0.5, $y+0.5, $width-2, $height-2);
	$cr->stroke;

	$cr->restore;
}

use constant
{
	CHECK_BOX_SIZE => 13,
};

sub check_box
{
	my ($cr, $x, $y, $checked) = @_;

	$cr->save;

	bevel_box ($cr, $x, $y, CHECK_BOX_SIZE, CHECK_BOX_SIZE);

	if ($checked) {
		set_hex_color ($cr, $BLACK);
		$cr->move_to ($x+3, $y+5);
		$cr->rel_line_to (2.5, 2);
		$cr->rel_line_to (4.5, -4);
		$cr->rel_line_to (0, 3);
		$cr->rel_line_to (-4.5, 4);
		$cr->rel_line_to (-2.5, -2);
		$cr->close_path;
		$cr->fill;
	}

	$cr->restore;
}

use constant
{
	RADIO_SIZE => CHECK_BOX_SIZE,
};

sub radio_button
{
	my ($cr, $x, $y, $checked) = @_;

	$cr->save;

	bevel_circle ($cr, $x, $y, RADIO_SIZE);

	if ($checked) {
		set_hex_color ($cr, $BLACK);
		$cr->arc (
		   $x + (RADIO_SIZE-1) / 2.0 + 0.5,
		   $y + (RADIO_SIZE-1) / 2.0 + 0.5,
		   (RADIO_SIZE-1) / 2.0 - 3.5,
		   0, 2 * M_PI);
		$cr->fill;
	}

	$cr->restore;
}

sub draw_bevels
{
	my ($cr, $width, $height) = @_;
	my $check_room = ($width - 20) / 3;
	my $check_pad = ($check_room - CHECK_BOX_SIZE) / 2;

	groovy_box ($cr, 5, 5, $width - 10, $height - 10);

	check_box ($cr, 10+$check_pad, 10+$check_pad, 0);
	check_box ($cr, $check_room+10+$check_pad, 10+$check_pad, 1);
	flat_box ($cr, 2 * $check_room+10+$check_pad, 10+$check_pad,
	          CHECK_BOX_SIZE, CHECK_BOX_SIZE);

	radio_button ($cr, 10+$check_pad, $check_room+10+$check_pad, 0);
	radio_button ($cr, $check_room+10+$check_pad, $check_room+10+$check_pad, 1);
	flat_circle ($cr, 2 * $check_room+10+$check_pad, $check_room+10+$check_pad, CHECK_BOX_SIZE);
}

{
	my $surface = Cairo::ImageSurface->create ('argb32', WIDTH, HEIGHT);
	my $cr = Cairo::Context->create ($surface);

	$cr->rectangle (0, 0, WIDTH, HEIGHT);
	set_hex_color ($cr, $BG_COLOR);
	$cr->fill;

	draw_bevels ($cr, WIDTH, HEIGHT);

	$surface->write_to_png ('bevels.png');
}
