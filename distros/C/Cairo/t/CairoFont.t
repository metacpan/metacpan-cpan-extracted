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
use utf8;

use Test::More tests => 29;

use constant IMG_WIDTH => 256;
use constant IMG_HEIGHT => 256;

use Cairo;

my $options = Cairo::FontOptions->create;
isa_ok ($options, 'Cairo::FontOptions');

is ($options->status, 'success');

$options->merge (Cairo::FontOptions->create);

ok ($options->equal ($options));

is ($options->hash, 0);

$options->set_antialias ('subpixel');
is ($options->get_antialias, 'subpixel');

$options->set_subpixel_order ('rgb');
is ($options->get_subpixel_order, 'rgb');

$options->set_hint_style ('full');
is ($options->get_hint_style, 'full');

$options->set_hint_metrics ('on');
is ($options->get_hint_metrics, 'on');

# --------------------------------------------------------------------------- #

my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
my $cr = Cairo::Context->create ($surf);
my $face = $cr->get_font_face;

is ($face->status, 'success');

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	ok (defined $face->get_type);
}

my $matrix = Cairo::Matrix->init_identity;
my $ctm = Cairo::Matrix->init_identity;

my $font = Cairo::ScaledFont->create ($face, $matrix, $ctm, $options);
isa_ok ($font, 'Cairo::ScaledFont');

SKIP: {
	skip 'scaled font tests', 10
		unless $font->status eq 'success';

	isa_ok ($font->extents, 'HASH');
	isa_ok ($font->glyph_extents ({ index => 1, x => 2, y => 3 }), 'HASH');

	skip 'new stuff', 8
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	$cr->set_scaled_font ($font);
	is ($font->status, 'success');
	is ($cr->status, 'success');

	ok (defined $font->get_type);

	isa_ok ($font->text_extents('Bla'), 'HASH');

	isa_ok ($font->get_font_face, 'Cairo::FontFace');
	isa_ok ($font->get_font_matrix, 'Cairo::Matrix');
	isa_ok ($font->get_ctm, 'Cairo::Matrix');
	isa_ok ($font->get_font_options, 'Cairo::FontOptions');
}

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 8, 0);

	isa_ok ($font->get_scale_matrix, 'Cairo::Matrix');

	my $text = 'æſðđŋ';
	my ($status, $glyphs, $clusters, $flags) =
		$font->text_to_glyphs (5, 10, $text);
	skip 'show_text_glyphs', 1
		unless $status eq 'success';
	$cr->show_text_glyphs ($text, $glyphs, $clusters, $flags);
	is ($cr->status, 'success');
}

# --------------------------------------------------------------------------- #

SKIP: {
	skip 'toy font face', 6
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 8, 0);

	my $face = Cairo::ToyFontFace->create ('Sans', 'italic', 'bold');
	isa_ok ($face, 'Cairo::ToyFontFace');
	isa_ok ($face, 'Cairo::FontFace');
	is ($face->status, 'success');

	is ($face->get_family, 'Sans');
	is ($face->get_slant, 'italic');
	is ($face->get_weight, 'bold');
}
