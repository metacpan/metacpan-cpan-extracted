#!/usr/bin/perl
#
# Copyright (c) 2004-2005 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#
# $Id$
#

use strict;
use warnings;

use Test::More tests => 48;

unless (eval 'use Test::Number::Delta; 1;') {
	my $reason = 'Test::Number::Delta not available';
	*delta_ok = sub { SKIP: { skip $reason, 1 } };
}

use constant IMG_WIDTH => 256;
use constant IMG_HEIGHT => 256;

use Cairo;

sub common_pattern_ok {
	my ($pat, $type) = @_;

	isa_ok ($pat, $type);
	isa_ok ($pat, 'Cairo::Pattern');

	$pat->set_extend ('repeat');
	is ($pat->get_extend, 'repeat', "$type set|get_extend");

	$pat->set_filter ('good');
	is ($pat->get_filter, 'good', "$type set|get_filter");

	my $matrix = Cairo::Matrix->init_identity;
	$pat->set_matrix ($matrix);
	isa_ok ($pat->get_matrix, 'Cairo::Matrix', "$type set|get_matrix");

	is ($pat->status, 'success', "$type status");
}

{
	my $pat = Cairo::SolidPattern->create_rgb(1.0, 0.0, 0.0);
	common_pattern_ok ($pat, 'Cairo::SolidPattern');
}

{
	my $pat = Cairo::SolidPattern->create_rgba(1.0, 0.0, 0.0, 1.0);
	common_pattern_ok ($pat, 'Cairo::SolidPattern');
}

{
	my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
	my $pat = Cairo::SurfacePattern->create ($surf);
	common_pattern_ok ($pat, 'Cairo::SurfacePattern');
}

{
	my $pat = Cairo::LinearGradient->create (1, 2, 3, 4);
	common_pattern_ok ($pat, 'Cairo::LinearGradient');
	isa_ok ($pat, 'Cairo::Gradient');

	$pat->add_color_stop_rgb (1, 0.5, 0.6, 0.7);
	$pat->add_color_stop_rgba (1, 0.5, 0.6, 0.7, 0.8);

	is ($pat->status, 'success');
}

{
	my $pat = Cairo::RadialGradient->create (1, 2, 3, 4, 5, 6);
	common_pattern_ok ($pat, 'Cairo::RadialGradient');
	isa_ok ($pat, 'Cairo::Gradient');

	$pat->add_color_stop_rgb (1, 0.5, 0.6, 0.7);
	$pat->add_color_stop_rgba (1, 0.5, 0.6, 0.7, 0.8);

	is ($pat->status, 'success');
}

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	my $pat = Cairo::RadialGradient->create (1, 2, 3, 4, 5, 6);
	is ($pat->get_type, 'radial');
}

SKIP: {
	skip 'new stuff', 13,
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 4, 0);

	{
		my $pat = Cairo::SolidPattern->create_rgb(1.0, 0.0, 0.0);
		my ($r, $g, $b, $a) = $pat->get_rgba;
		delta_ok ($r, 1.0);
		delta_ok ($g, 0.0);
		delta_ok ($b, 0.0);
		delta_ok ($a, 1.0);
		is ($pat->status, 'success');
	}

	{
		my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
		my $pat = Cairo::SurfacePattern->create ($surf);
		isa_ok ($pat->get_surface, 'Cairo::ImageSurface');
		is ($pat->status, 'success');
	}

	{
		my $pat = Cairo::LinearGradient->create (1, 2, 3, 4);
		$pat->add_color_stop_rgba (0.25, 1, 0, 1, 0);
		$pat->add_color_stop_rgba (0.75, 0, 1, 0, 1);
		delta_ok ([$pat->get_color_stops], [[0.25, 1, 0, 1, 0], [0.75, 0, 1, 0, 1]]);
		is ($pat->status, 'success');
	}

	{
		my $pat = Cairo::LinearGradient->create (1.5, 2.5, 3.5, 4.5);
		delta_ok ([$pat->get_points], [1.5, 2.5, 3.5, 4.5]);
		is ($pat->status, 'success');
	}

	{
		my $pat = Cairo::RadialGradient->create (1.5, 2.5, 3.5, 4.5, 5.5, 6.5);
		delta_ok ([$pat->get_circles], [1.5, 2.5, 3.5, 4.5, 5.5, 6.5]);
		is ($pat->status, 'success');
	}
}
