#!/usr/bin/perl

# This is a Perl port of the C program cairo-demo/png/snapping.c.  Original
# copyright:

# Copyright (c) 2004 Red Hat, Inc.
#
# Permission to use, copy, modify, distribute, and sell this software
# and its documentation for any purpose is hereby granted without
# fee, provided that the above copyright notice appear in all copies
# and that both that copyright notice and this permission notice
# appear in supporting documentation, and that the name of
# Red Hat, Inc. not be used in advertising or publicity pertaining to
# distribution of the software without specific, written prior
# permission. Red Hat, Inc. makes no representations about the
# suitability of this software for any purpose.  It is provided "as
# is" without express or implied warranty.
#
# RED HAT, INC. DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
# SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS, IN NO EVENT SHALL RED HAT, INC. BE LIABLE FOR ANY SPECIAL,
# INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Author: Carl D. Worth <cworth@cworth.org>

use strict;
use warnings;
use Cairo;
use POSIX qw(floor);

# This demo demonstrates how to perform device-pixel snapping for
# horizontal and vertically aligned strokes and fills. The technique
# used here is designed to work with any stroke width as well as any
# scale factor or translation amount in the current transformation.
# The code here may not provide good results for curved objects or
# when the transformation includes rotation and or shear components.
#
# The output includes four groups of nested boxes. The top two groups
# consists of 5 filled boxes, alternating between black and
# white. The bottom two groups show 5 white stroked boxes. Within
# each group, the path for each box is constructed the same way, but
# with a different transform. For the two groups on the right, all
# coordinates in the path are snapped before drawing so that the
# boundary of each shape will align properly with the device pixel
# grid.

use constant
{
	WIDTH => 175,
	HEIGHT => 175,
};

# These snapping functions are designed to work properly with a
# matrix that has only scale and translate components. I make no
# guarantees about how they will behave under more interesting
# transformations (such as rotation or shear).

# Snap the given coordinate so that it is on an integer coordinate of
# the device pixel grid. This is the appropriate snapping to use for
# horizontal/vertical portions of paths to be filled.
sub snap_point_for_fill
{
	my ($cr, $x, $y) = @_;

	# Convert to device space, round, then convert back to user space.
	($x, $y) = $cr->user_to_device ($x, $y);
	$x = floor ($x + 0.5);
	$y = floor ($y + 0.5);
	($x, $y) = $cr->device_to_user ($x, $y);

	return ($x, $y);
}

# Snap the given path coordinate as appropriate for a path to be
# stroked. This snapping is dependent on the current line width, so
# it should be called when the line width is set to the value that
# will be used for the stroke.
#
# The snapping is performed so that the stroke boundary of horizontal
# and vertical portions will lie precisely between device pixels. If
# the device-space line width is not an integer, then only one side
# of the path will be properly aligned. The snap_line_width function
# below can be used to constrain the line width to be an integer in
# device space.
sub snap_point_for_stroke
{
	my ($cr, $x, $y) = @_;

	# Round in device space after adding the fractional portion of
	# one-half the (device space) line width.
	my $x_width_dev_2 = $cr->get_line_width;
	my $y_width_dev_2 = $cr->get_line_width;
	($x_width_dev_2, $y_width_dev_2) =
		$cr->user_to_device_distance ($x_width_dev_2, $y_width_dev_2);
	$x_width_dev_2 *= 0.5;
	$y_width_dev_2 *= 0.5;

	my $x_offset = $x_width_dev_2 - int $x_width_dev_2;
	my $y_offset = $y_width_dev_2 - int $y_width_dev_2;

	($x, $y) = $cr->user_to_device ($x, $y);
	$x = floor ($x + $x_offset + 0.5);
	$y = floor ($y + $y_offset + 0.5);
	$x -= $x_offset;
	$y -= $y_offset;
	($x, $y) = $cr->device_to_user ($x, $y);

	return ($x, $y);
}

# Snap the line width so that it is an integer number of device
# pixels. Cairo currently only supports symmetrical pens, so if the
# current transformation has non-uniform scaling in X and Y, we won't
# be able to satisfy the constraint in both dimensions. So, this
# function examines both directions and snaps to the dimension that
# has the larger error.
sub snap_line_width
{
	my ($cr) = @_;

	my $x_width = $cr->get_line_width;
	my $y_width = $cr->get_line_width;

	($x_width, $y_width) = $cr->user_to_device_distance ($x_width, $y_width);

	# If the line width is less than 1 then it will round to 0 and
	# disappear. Instead, we clamp it to 1.0, but we must preserve
	# its sign for the case of a reflecting transformation.
	my $x_width_snapped = floor ($x_width + 0.5);
	if (abs ($x_width_snapped) < 1.0) {
		$x_width_snapped = $x_width > 0 ? 1.0 : -1.0;
	}

	my $y_width_snapped = floor ($y_width + 0.5);
	if (abs ($y_width_snapped) < 1.0) {
		$y_width_snapped = $y_width > 0 ? 1.0 : -1.0;
	}

	my $x_error = abs ($x_width - $x_width_snapped);
	my $y_error = abs ($y_width - $y_width_snapped);

	($x_width_snapped, $y_width_snapped) =
		$cr->device_to_user_distance
			($x_width_snapped, $y_width_snapped);

	$cr->set_line_width
		($x_error > $y_error ? $x_width_snapped : $y_width_snapped);
}

sub snap_point
{
	my ($spc, $x, $y) = @_;

	return $spc->{fill}
		? snap_point_for_fill ($spc->{cr}, $x, $y)
		: snap_point_for_stroke ($spc->{cr}, $x, $y);
}

sub spc_new_path_perhaps
{
	my ($spc) = @_;

	if ($spc->{first}) {
		$spc->{cr}->new_path;
		$spc->{first} = 0;
	}
}

sub spc_move_to
{
	my ($spc, $x, $y) = @_;

	spc_new_path_perhaps ($spc);
	($x, $y) = snap_point ($spc, $x, $y);
	$spc->{cr}->move_to ($x, $y);
}

sub spc_line_to
{
	my ($spc, $x, $y) = @_;

	spc_new_path_perhaps ($spc);
	($x, $y) = snap_point ($spc, $x, $y);
	$spc->{cr}->line_to ($x, $y);
}

sub spc_curve_to
{
	my ($spc, $x1, $y1, $x2, $y2, $x3, $y3) = @_;

	spc_new_path_perhaps ($spc);
	($x1, $y1) = snap_point ($spc, $x1, $y1);
	($x2, $y2) = snap_point ($spc, $x2, $y2);
	($x3, $y3) = snap_point ($spc, $x3, $y3);
	$spc->{cr}->curve_to ($x1, $y1, $x2, $y2, $x3, $y3);
}

sub spc_close_path
{
	my ($spc) = @_;

	spc_new_path_perhaps ($spc);
	$spc->{cr}->close_path;
}

sub snap_path_for_fill
{
	my ($cr) = @_;

	my $spc = {
		first => 1,
		fill => 1,
		cr => $cr,
	};

	my $path = $cr->copy_path;
	use Data::Dumper;
	foreach (@{$path}) {
		if ($_->{type} eq 'move-to') {
			spc_move_to ($spc, @{$_->{points}->[0]});
		}

		elsif ($_->{type} eq 'line-to') {
			spc_line_to ($spc, @{$_->{points}->[0]});
		}

		elsif ($_->{type} eq 'curve-to') {
			spc_curve_to ($spc, @{$_->{points}->[0]},
			                    @{$_->{points}->[1]},
			                    @{$_->{points}->[2]});
		}

		else {
			spc_close_path ($spc);
		}
	}
}

sub snap_path_for_stroke
{
	my ($cr) = @_;

	my $spc = {
		first => 1,
		fill => 0,
		cr => $cr,
	};

	snap_line_width ($cr);

	my $path = $cr->copy_path;
	use Data::Dumper;
	foreach (@{$path}) {
		if ($_->{type} eq 'move-to') {
			spc_move_to ($spc, @{$_->{points}->[0]});
		}

		elsif ($_->{type} eq 'line-to') {
			spc_line_to ($spc, @{$_->{points}->[0]});
		}

		elsif ($_->{type} eq 'curve-to') {
			spc_curve_to ($spc, @{$_->{points}->[0]},
			                    @{$_->{points}->[1]},
			                    @{$_->{points}->[2]});
		}

		else {
			spc_close_path ($spc);
		}
	}
}

use constant {
	NUM_BOXES => 5,
	BOX_WIDTH => 13,
	# We need non-integer scale factors to demonstrate anything
	# interesting.
	SCALE_TWEAK => 1.11,
};

sub draw_nested
{
	my ($cr, $style, $snapping) = @_;
	my $offset = SCALE_TWEAK * BOX_WIDTH / 2.0;

	$cr->save;

	$cr->set_line_width (1.0);

	foreach (0 .. NUM_BOXES - 1) {
		my $scale = SCALE_TWEAK * (NUM_BOXES - $_);

		$cr->save;
		{
			$cr->scale ($scale, $scale);
			$cr->rectangle (0, 0, BOX_WIDTH, BOX_WIDTH);

			if ($style eq 'nested-fills') {
				if ($snapping eq 'snapping') {
					snap_path_for_fill ($cr);
				}

				if ($_ % 2 == 0) {
					$cr->set_source_rgb (1, 1, 1);
				} else {
					$cr->set_source_rgb (0, 0, 0);
				}

				$cr->fill;
			} else {
				if ($snapping eq 'snapping') {
					snap_path_for_stroke ($cr);
				}

				$cr->set_source_rgb (1, 1, 1);
				$cr->stroke;
			}
		}
		$cr->restore;

		$cr->translate ($offset, $offset);
	}

	$cr->restore;
}

sub draw
{
	my ($cr, $width, $height) = @_;

	$cr->translate (6, 6);

	draw_nested ($cr, 'nested-fills', 'no-snapping');

	$cr->translate ($width / 2, 0);

	draw_nested ($cr, 'nested-fills', 'snapping');

	$cr->translate (-$width / 2, $height / 2);

	draw_nested ($cr, 'nested-strokes', 'no-snapping');

	$cr->translate ($width / 2, 0);

	draw_nested ($cr, 'nested-strokes', 'snapping');
}

{
	my $surface = Cairo::ImageSurface->create ('argb32', WIDTH, HEIGHT);
	my $cr = Cairo::Context->create ($surface);

	$cr->rectangle (0, 0, WIDTH, HEIGHT);
	$cr->set_source_rgb (0, 0, 0);
	$cr->fill;

	draw ($cr, WIDTH, HEIGHT);

	$surface->write_to_png ('snapping.png');
}
