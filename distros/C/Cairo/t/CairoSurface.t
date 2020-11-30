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

use Config; # for byteorder

use Test::More tests => 100;

use constant IMG_WIDTH => 256;
use constant IMG_HEIGHT => 256;

use Cairo;

unless (eval 'use Test::Number::Delta; 1;') {
	my $reason = 'Test::Number::Delta not available';
	*delta_ok = sub { SKIP: { skip $reason, 1 } };
}

my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
isa_ok ($surf, 'Cairo::ImageSurface');
isa_ok ($surf, 'Cairo::Surface');

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	is ($surf->get_content, 'color');
	is ($surf->get_format, 'rgb24');
}

is ($surf->get_width, IMG_WIDTH);
is ($surf->get_height, IMG_HEIGHT);

{
	my $data = pack ('CCCC', 0, 0, 0, 0);
	my $surf = Cairo::ImageSurface->create_for_data (
	             $data, 'argb32', 1, 1, 4);
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'new stuff', 4
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		is ($surf->get_data, $data);
		is ($surf->get_stride, 4);

		# Change the image data and make sure $data gets updated accordingly.
		my $cr = Cairo::Context->create ($surf);
		$cr->set_source_rgba (1.0, 0, 0, 1.0);
		$cr->rectangle (0, 0, 1, 1);
		$cr->fill;

		is ($surf->get_data, $data);

		my $bo = $Config{byteorder}+1;
		if ($bo == 1234) {
			is ($surf->get_data, pack ('CCCC', 0, 0, 255, 255));
		} elsif ($bo == 4321) {
			is ($surf->get_data, pack ('CCCC', 255, 255, 0, 0));
		} else {
			ok (1, 'Skipping get_data test; unknown endianness');
		}
	}
}

my $similar = Cairo::Surface->create_similar ($surf, 'color', IMG_WIDTH, IMG_HEIGHT);
isa_ok ($similar, 'Cairo::ImageSurface');
isa_ok ($similar, 'Cairo::Surface');

# Test that create_similar can be called with both conventions.
{
	my $similar = $surf->create_similar ('color', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($similar, 'Cairo::ImageSurface');
	isa_ok ($similar, 'Cairo::Surface');

	eval { Cairo::Surface->create_similar (1, 2) };
	like ($@, qr/Usage/);

	eval { Cairo::Surface->create_similar (1, 2, 3, 4, 5) };
	like ($@, qr/Usage/);
}

# Test that the enum wrappers differentiate between color and color-alpha.
SKIP: {
	skip 'content tests', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	my $tmp = Cairo::Surface->create_similar ($surf, 'color-alpha', IMG_WIDTH, IMG_HEIGHT);
	is ($tmp->get_content, 'color-alpha');
	$tmp = Cairo::Surface->create_similar ($surf, 'color', IMG_WIDTH, IMG_HEIGHT);
	is ($tmp->get_content, 'color');
}

$surf->set_device_offset (23, 42);

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

	is_deeply ([$surf->get_device_offset], [23, 42]);

	$surf->set_fallback_resolution (72, 72);

	is ($surf->get_type, 'image');
}

is ($surf->status, 'success');

isa_ok ($surf->get_font_options, 'Cairo::FontOptions');

$surf->mark_dirty;
$surf->mark_dirty_rectangle (10, 10, 10, 10);
$surf->flush;

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 6, 0);

	$surf->copy_page;
	$surf->show_page;

	like (Cairo::Format::stride_for_width ('argb32', 23), qr/\A\d+\z/);
}

SKIP: {
	skip 'new stuff', 2
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 8, 0);

	$surf->set_fallback_resolution (72, 72);
	delta_ok ([$surf->get_fallback_resolution], [72, 72]);

	ok (defined $surf->has_show_text_glyphs);
}

SKIP: {
	skip 'new stuff', 1
		unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 10, 0);

	my $rect_surf = Cairo::Surface->create_for_rectangle ($surf, 0, 0, 10, 10);
	isa_ok ($rect_surf, 'Cairo::Surface');
}

$surf->finish;

# --------------------------------------------------------------------------- #

sub clear {
	if (Cairo::VERSION() < Cairo::VERSION_ENCODE (1, 2, 0)) {
		my $cr = Cairo::Context->create ($surf);
		$cr->set_operator ('clear');
		$cr->paint;
	}
}

SKIP: {
	skip 'png surface', 16
		unless Cairo::HAS_PNG_FUNCTIONS;

	my $surf = Cairo::ImageSurface->create ('rgb24', IMG_WIDTH, IMG_HEIGHT);
	clear ($surf);
	is ($surf->write_to_png ('tmp.png'), 'success');

	is ($surf->write_to_png_stream (sub {
		my ($closure, $data) = @_;
		is ($closure, 'blub');
		like ($data, qr/PNG/);
		die 'no-memory';
	}, 'blub'), 'no-memory');

	is ($surf->write_to_png_stream (sub {
		my ($closure, $data) = @_;
		is ($closure, undef);
		like ($data, qr/PNG/);
		die 'no-memory';
	}), 'no-memory');

	$surf = Cairo::ImageSurface->create_from_png ('tmp.png');
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');

	open my $fh, 'tmp.png';
	$surf = Cairo::ImageSurface->create_from_png_stream (sub {
		my ($closure, $length) = @_;
		my $buffer;

		if ($length != sysread ($fh, $buffer, $length)) {
			die 'no-memory';
		}

		return $buffer;
	});
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');
	is ($surf->status, 'success');
	close $fh;

	$surf = Cairo::ImageSurface->create_from_png_stream (sub {
		my ($closure, $length) = @_;
		is ($closure, 'blub');
		die 'read-error';
	}, 'blub');
	isa_ok ($surf, 'Cairo::ImageSurface');
	isa_ok ($surf, 'Cairo::Surface');
	is ($surf->status, 'read-error');

	unlink 'tmp.png';
}

SKIP: {
	skip 'pdf surface', 18
		unless Cairo::HAS_PDF_SURFACE;

	my $surf = Cairo::PdfSurface->create ('tmp.pdf', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::PdfSurface');
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'new stuff', 0
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		$surf->set_size (23, 42);
	}

	# create_similar might return any kind of surface
	$surf = Cairo::Surface->create_similar ($surf, 'alpha', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'create_for_stream on pdf surfaces', 4
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		$surf = Cairo::PdfSurface->create_for_stream (sub {
			my ($closure, $data) = @_;
			is ($closure, 'blub');
			like ($data, qr/PDF/);
			die 'write-error';
		}, 'blub', IMG_WIDTH, IMG_HEIGHT);
		isa_ok ($surf, 'Cairo::PdfSurface');
		isa_ok ($surf, 'Cairo::Surface');
	}

	SKIP: {
		skip 'new stuff', 6
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 10, 0);

		my $surf = Cairo::PdfSurface->create ('tmp.pdf', IMG_WIDTH, IMG_HEIGHT);
		$surf->restrict_to_version ('1-4');
		$surf->restrict_to_version ('1-5');

		my @versions = Cairo::PdfSurface::get_versions();
		ok (scalar @versions > 0);
		is ($versions[0], '1-4');

		@versions = Cairo::PdfSurface->get_versions();
		ok (scalar @versions > 0);
		is ($versions[0], '1-4');

		like (Cairo::PdfSurface::version_to_string('1-4'), qr/1\.4/);
		like (Cairo::PdfSurface->version_to_string('1-4'), qr/1\.4/);
	}

	SKIP: {
		skip 'new stuff', 4
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 10, 0);

		my $mime_data = 'mime data for {set,get}_mime_data';
		is ($surf->MIME_TYPE_JPEG, 'image/jpeg');
		is ($surf->set_mime_data($surf->MIME_TYPE_JPEG, $mime_data), 'success');

		my $recovered_mime_data = $surf->get_mime_data('unset mime type');
		is ($recovered_mime_data, undef);

		$recovered_mime_data = $surf->get_mime_data($surf->MIME_TYPE_JPEG);
		is ($recovered_mime_data, $mime_data);
		}

	SKIP: {
		skip 'new stuff', 2
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 12, 0);

		is ($surf->supports_mime_type(Cairo::Surface::MIME_TYPE_JPEG), 1);
		is ($surf->supports_mime_type('unsupported mime type'), 0);

	}

	SKIP: {
		skip 'new stuff', 1
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 16, 0);

		$surf->set_metadata("title","Testing metadata");
		$surf->set_metadata("author","Johan Vromans");
		$surf->set_metadata("subject","cairo_pdf_set_metadata");
		ok(1);	# No get_metadata, so assume OK if we're still alive
	}

	SKIP: {
		skip 'new stuff', 3
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 16, 0);

		$surf->set_page_label('Page label');
		is ($surf->status(), 'success');

		$surf->set_thumbnail_size(20, 20);
		is ($surf->status(), 'success');

		my $parent = $surf->add_outline($surf->OUTLINE_ROOT(), 'Cover', "dest='page=1'", ['bold']);
		$parent = $surf->add_outline($parent, 'Chapter 1', 'page=2', ['bold', 'open']);
		$parent = $surf->add_outline($parent, 'Section 1', 'page=2', ['open']);
		$parent = $surf->add_outline($parent, 'Section 1.1', 'page=2', ['italic']);
		$parent = $surf->add_outline($parent, 'Review', 'page=2', []);
		is ($surf->status(), 'success');
	}

	unlink 'tmp.pdf';
}

SKIP: {
	skip 'ps surface', 14
		unless Cairo::HAS_PS_SURFACE;

	my $surf = Cairo::PsSurface->create ('tmp.ps', IMG_WIDTH, IMG_HEIGHT);

	skip 'create returned no ps surface', 15
		unless defined $surf && $surf->isa ('Cairo::PsSurface');

	isa_ok ($surf, 'Cairo::PsSurface');
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'new stuff', 0
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		$surf->set_size (23, 42);

		$surf->dsc_comment("Bla?");
		$surf->dsc_begin_setup;
		$surf->dsc_begin_page_setup;
	}

	# create_similar might return any kind of surface
	$surf = Cairo::Surface->create_similar ($surf, 'alpha', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::Surface');

	unlink 'tmp.ps';

	SKIP: {
		skip 'create_for_stream on ps surfaces', 4
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 2, 0);

		skip 'create_for_stream on ps surfaces', 4
			if (Cairo::VERSION() >= Cairo::VERSION_ENCODE (1, 4, 0) &&
			    Cairo::VERSION() < Cairo::VERSION_ENCODE (1, 4, 8));

		$surf = Cairo::PsSurface->create_for_stream (sub {
			my ($closure, $data) = @_;
			is ($closure, 'blub');
			like ($data, qr/PS/);
			die 'write-error';
		}, 'blub', IMG_WIDTH, IMG_HEIGHT);
		isa_ok ($surf, 'Cairo::PsSurface');
		isa_ok ($surf, 'Cairo::Surface');
	}

	SKIP: {
		skip 'new stuff', 7
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 6, 0);

		$surf->restrict_to_level ('2');
		$surf->restrict_to_level ('3');

		my @levels = Cairo::PsSurface::get_levels();
		ok (scalar @levels > 0);
		is ($levels[0], '2');

		@levels = Cairo::PsSurface->get_levels();
		ok (scalar @levels > 0);
		is ($levels[0], '2');

		like (Cairo::PsSurface::level_to_string('2'), qr/2/);
		like (Cairo::PsSurface->level_to_string('3'), qr/3/);

		$surf->set_eps (1);
		is ($surf->get_eps, 1);
	}
}

SKIP: {
	skip 'svg surface', 12
		unless Cairo::HAS_SVG_SURFACE;

	my $surf = Cairo::SvgSurface->create ('tmp.svg', IMG_WIDTH, IMG_HEIGHT);
	isa_ok ($surf, 'Cairo::SvgSurface');
	isa_ok ($surf, 'Cairo::Surface');

	$surf->restrict_to_version ('1-1');
	$surf->restrict_to_version ('1-2');

	unlink 'tmp.svg';

	SKIP: {
		skip 'create_for_stream on svg surfaces', 4
			if (Cairo::VERSION() >= Cairo::VERSION_ENCODE (1, 4, 0) &&
			    Cairo::VERSION() < Cairo::VERSION_ENCODE (1, 4, 8));

		$surf = Cairo::SvgSurface->create_for_stream (sub {
			my ($closure, $data) = @_;
			is ($closure, 'blub');
			like ($data, qr/xml/);
			die 'write-error';
		}, 'blub', IMG_WIDTH, IMG_HEIGHT);
		isa_ok ($surf, 'Cairo::SvgSurface');
		isa_ok ($surf, 'Cairo::Surface');
	}

	my @versions = Cairo::SvgSurface::get_versions();
	ok (scalar @versions > 0);
	is ($versions[0], '1-1');

	@versions = Cairo::SvgSurface->get_versions();
	ok (scalar @versions > 0);
	is ($versions[0], '1-1');

	like (Cairo::SvgSurface::version_to_string('1-1'), qr/1\.1/);
	like (Cairo::SvgSurface->version_to_string('1-1'), qr/1\.1/);
}

SKIP: {
	skip 'recording surface', 7
		unless Cairo::HAS_RECORDING_SURFACE;

	my $surf = Cairo::RecordingSurface->create (
	             'color',
	             {x=>10, y=>10, width=>5, height=>5});
	isa_ok ($surf, 'Cairo::RecordingSurface');
	isa_ok ($surf, 'Cairo::Surface');

	# Test that the extents rectangle was marshalled correctly.
	my $cr = Cairo::Context->create ($surf);
	$cr->move_to (0, 0);
	$cr->line_to (30, 30);
	$cr->paint;
	is_deeply ([$surf->ink_extents], [10, 10, 5, 5]);

	$surf = Cairo::RecordingSurface->create ('color', undef);
	isa_ok ($surf, 'Cairo::RecordingSurface');
	isa_ok ($surf, 'Cairo::Surface');

	SKIP: {
		skip 'get_extents', 2
			unless Cairo::VERSION >= Cairo::VERSION_ENCODE (1, 12, 0);

		$surf = Cairo::RecordingSurface->create ('color', undef);
		is ($surf->get_extents(), undef);

		$surf =  Cairo::RecordingSurface->create ('color', {x => 5, y => 10, width => 15, height => 20});
		is_deeply ($surf->get_extents(), {x => 5, y => 10, width => 15, height => 20});
	}
}
