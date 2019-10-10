#!/usr/bin/perl
#
# Copyright (c) 2004-2012 by the cairo perl team (see the file README)
#
# Licensed under the LGPL, see LICENSE file for more information.
#
# $Id$
#

use strict;
use warnings;

use Test::More tests => 72;

unless (eval 'use Test::Number::Delta; 1;') {
	my $reason = 'Test::Number::Delta not available';
	*delta_ok = sub { SKIP: { skip $reason, 1 } };
}

use constant IMG_WIDTH => 256;
use constant IMG_HEIGHT => 256;

use Cairo;

my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
isa_ok ($surf, 'Cairo::Surface');

my $cr = Cairo::Context->create ($surf);
isa_ok ($cr, 'Cairo::Context');

$cr->save;
$cr->restore;

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	$cr->push_group();
	isa_ok ($cr->get_group_target, 'Cairo::Surface');
	isa_ok ($cr->pop_group(), 'Cairo::Pattern');

	$cr->push_group_with_content('color');
	$cr->pop_group_to_source();
}

$cr->set_operator ('clear');
is ($cr->get_operator, 'clear');

$cr->set_source_rgb (0.5, 0.6, 0.7);
$cr->set_source_rgba (0.5, 0.6, 0.7, 0.8);

my $pat = Cairo::SurfacePattern->create ($surf);

$cr->set_source ($pat);
$cr->set_source_surface ($surf, 23, 42);

$cr->set_tolerance (0.75);
delta_ok ($cr->get_tolerance, 0.75);

$cr->set_antialias ('subpixel');
is ($cr->get_antialias, 'subpixel');

$cr->set_fill_rule ('winding');
is ($cr->get_fill_rule, 'winding');

$cr->set_line_width (3);
is ($cr->get_line_width, 3);

$cr->set_line_cap ('butt');
is ($cr->get_line_cap, 'butt');

$cr->set_line_join ('miter');
is ($cr->get_line_join, 'miter');

$cr->set_dash (0, 2, 4, 6, 4, 2);
$cr->set_dash (0);

SKIP: {
	skip 'new stuff', 4
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 4, 0);

	$cr->set_dash (0.5, 2.3, 4.5, 6.7, 4.5, 2.3);
	my ($offset, @dashes) = $cr->get_dash;
	is ($offset, 0.5);
	delta_ok (\@dashes, [2.3, 4.5, 6.7, 4.5, 2.3]);

	$cr->set_dash (0);
	($offset, @dashes) = $cr->get_dash;
	is ($offset, 0);
	is_deeply (\@dashes, []);
}

$cr->set_miter_limit (2.2);
delta_ok ($cr->get_miter_limit, 2.2);

$cr->translate (2.2, 3.3);
$cr->scale (2.2, 3.3);
$cr->rotate (2.2);

my $mat = Cairo::Matrix->init_identity;
isa_ok ($mat, 'Cairo::Matrix');

$cr->set_matrix ($mat);
isa_ok ($cr->get_matrix, 'Cairo::Matrix');

$cr->transform ($mat);
$cr->identity_matrix;

is_deeply ([$cr->user_to_device (23, 42)], [23, 42]);
is_deeply ([$cr->user_to_device_distance (1, 2)], [1, 2]);
is_deeply ([$cr->device_to_user (23, 42)], [23, 42]);
is_deeply ([$cr->device_to_user_distance (1, 2)], [1, 2]);

$cr->new_path;

SKIP: {
	skip 'new stuff', 0
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	$cr->new_sub_path;
}

$cr->move_to (1.1, 2.2);
$cr->line_to (2.2, 3.3);
$cr->curve_to (3.3, 4.4, 5.5, 6.6, 7.7, 8.8);
$cr->arc (4.4, 5.5, 6.6, 7.7, 8.8);
$cr->arc_negative (5.5, 6.6, 7.7, 8.8, 9.9);
$cr->rel_move_to (6.6, 7.7);
$cr->rel_line_to (8.8, 9.9);
$cr->rel_curve_to (9.9, 0.0, 1.1, 2.2, 3.3, 4.4);
$cr->rectangle (0.0, 1.1, 2.2, 3.3);
$cr->close_path;

SKIP: {
	skip 'new stuff', 4
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 5, 8);

	my ($x1, $y1, $x2, $y2) = $cr->path_extents;
	foreach ($x1, $y1, $x2, $y2) {
		ok (defined $_);
	}
}

$cr->paint;
$cr->paint_with_alpha (0.5);
$cr->mask ($pat);
$cr->mask_surface ($surf, 23, 42);
$cr->stroke;
$cr->stroke_preserve;
$cr->fill;
$cr->fill_preserve;
$cr->copy_page;
$cr->show_page;

ok (!$cr->in_stroke (23, 42));
ok (!$cr->in_fill (23, 42));

my @ext = $cr->stroke_extents;
is (@ext, 4);

@ext = $cr->fill_extents;
is (@ext, 4);

$cr->clip;
$cr->clip_preserve;
$cr->reset_clip;

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 10, 0);

	ok ($cr->in_clip (23, 42));
}

SKIP: {
	skip 'new stuff', 7
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 4, 0);

	$cr->rectangle (0, 0, 128, 128);
	$cr->clip;

	my @extents = $cr->clip_extents;
	is (@extents, 4);
	is ($extents[0], 0);
	is ($extents[1], 0);
	is ($extents[2], 128);
	is ($extents[3], 128);

	my @list = $cr->copy_clip_rectangle_list;
	is (@list, 1);
	is_deeply ($list[0], { x => 0, y => 0, width => 128, height => 128 });
}

$cr->select_font_face ('Sans', 'normal', 'normal');
$cr->set_font_size (12);

$cr->set_font_matrix ($mat);
isa_ok ($cr->get_font_matrix, 'Cairo::Matrix');

my $opt = Cairo::FontOptions->create;

$cr->set_font_options ($opt);
ok ($opt->equal ($cr->get_font_options));

my @glyphs = ({ index => 1, x => 2, y => 3 },
              { index => 2, x => 3, y => 4 },
              { index => 3, x => 4, y => 5 });

$cr->show_text ('Urgs?');
$cr->show_glyphs (@glyphs);

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 8, 0);

	my @clusters = map { {num_bytes => 1, num_glyphs => 1} } (1 .. 3);
	my $text = 'abc';
	$cr->show_text_glyphs ($text, \@glyphs, \@clusters, ['backward']);
	is ($cr->status, 'success');
}

my $face = $cr->get_font_face;
isa_ok ($face, 'Cairo::FontFace');
$cr->set_font_face ($face);

my $ext = $cr->font_extents;
isa_ok ($ext, 'HASH');
ok (exists $ext->{'ascent'});
ok (exists $ext->{'descent'});
ok (exists $ext->{'height'});
ok (exists $ext->{'max_x_advance'});
ok (exists $ext->{'max_y_advance'});

foreach $ext ($cr->text_extents ('Urgs?'),
              $cr->glyph_extents (@glyphs)) {
	isa_ok ($ext, 'HASH');
	ok (exists $ext->{'x_bearing'});
	ok (exists $ext->{'y_bearing'});
	ok (exists $ext->{'width'});
	ok (exists $ext->{'height'});
	ok (exists $ext->{'x_advance'});
	ok (exists $ext->{'y_advance'});
}

$cr->text_path ('Urgs?');
$cr->glyph_path (@glyphs);

SKIP: {
	skip 'new stuff', 0
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	my $options = Cairo::FontOptions->create;
	my $matrix = Cairo::Matrix->init_identity;
	my $ctm = Cairo::Matrix->init_identity;
	my $font = Cairo::ScaledFont->create ($face, $matrix, $ctm, $options);
	$cr->set_scaled_font ($font);
}

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 4, 0);

	isa_ok ($cr->get_scaled_font, 'Cairo::ScaledFont');
}

isa_ok ($cr->get_source, 'Cairo::Pattern');

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 6, 0);

	ok ($cr->has_current_point);
}

my @pnt = $cr->get_current_point;
is (@pnt, 2);

isa_ok ($cr->get_target, 'Cairo::Surface');

my $path = $cr->copy_path;
isa_ok ($path, 'ARRAY');

$path = $cr->copy_path_flat;
isa_ok ($path, 'ARRAY');

$cr->append_path ($path);

is ($cr->status, 'success');

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 16, 0);

	$cr->tag_begin("Link","https://www.perl.org");
	is ($cr->status, 'success');
	$cr->tag_end("Link");
	is ($cr->status, 'success');
}
