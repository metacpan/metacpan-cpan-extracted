#! /usr/bin/perl

# Adapted and translated to Perl from the test/mime-unique-id.c file in the
# Cairo (version 1.17.3) source repository.

# Check that source surfaces with same CAIRO_MIME_TYPE_UNIQUE_ID are
# embedded only once in PDF/PS.
#
# To exercise all the surface embedding code in PDF, four types of
# source surfaces are painted on each page, each with its own UNIQUE_ID:
# - an image surface
# - a recording surface with a jpeg mime attached
# - a bounded recording surface
# - an unbounded recording surface.
#
# Four pages are generated. Each source is clipped starting with the
# smallest area on the first page increasing to the unclipped size on
# the last page. This is to ensure the output does not embed the
# source clipped to a smaller size than used on subsequent pages.


use strict;
use warnings;
use Cairo;

use Fcntl;

use feature 'say';

use constant
	{
	NUM_PAGES		=> 4,
	WIDTH			=> 275,
	HEIGHT			=> 275,
	RECORDING_SIZE		=> 800,
	TILE_SIZE		=> 40,
	PNG_FILENAME		=> 'romedalen.png',
	JPG_FILENAME		=> 'romedalen.jpg',
	OUTPUT_FILENAME		=> 'mime-unique-id.perl.pdf',
	M_PI			=> 3.1415926,
	};


sub create_image_surface
	{
	my $surface = Cairo::ImageSurface->create_from_png(PNG_FILENAME);
	my $status = $surface->status();
	if ($status ne 'success')
		{
		say $surface->status();
		die;
		}

	$surface->set_mime_data($surface->MIME_TYPE_UNIQUE_ID, PNG_FILENAME);

	$surface->set_mime_data($surface->MIME_TYPE_UNIQUE_ID, 'image');

	return $surface;
	}


sub create_recording_surface_with_mime_jpg
	{
	my $surface = Cairo::RecordingSurface->create('alpha', {x => 0, y => 0, width => 1, height => 1});
	if ($surface->status() ne 'success')
		{
		say $surface->status();
		die;
		}

	my ($FH, $want, $data);
	unless (sysopen($FH, JPG_FILENAME, O_RDONLY|O_BINARY))
		{
		die;
		}
	$want = -s $FH;
	$data = '';
	while (1)
		{
		my $rc = sysread($FH, $data, $want, length($data));
			die unless defined $rc;
		last if $rc == 0;
		$want -= $rc;
		last if $want <= 0;
		}
	close($FH);

	$surface->set_mime_data($surface->MIME_TYPE_JPEG, $data);
	if ($surface->status() ne 'success')
		{
		say $surface->status();
		die;
		}

	$surface->set_mime_data($surface->MIME_TYPE_UNIQUE_ID, 'jpeg');
	if ($surface->status() ne 'success')
		{
		say $surface->status();
		die;
		}

	return $surface;
	}


sub draw_tile
	{
	my ($cr) = @_;

	$cr->move_to(10+5, 10);
	$cr->arc(10, 10, 5, 0, 2*M_PI);
	$cr->close_path();
	$cr->set_source_rgb(1, 0, 0);
	$cr->fill();

	$cr->move_to(30, 10-10*0.43);
	$cr->line_to(25, 10+10*0.43);
	$cr->line_to(35, 10+10*0.43);
	$cr->close_path();
	$cr->set_source_rgb(0, 1, 0);
	$cr->fill();

	$cr->rectangle(5, 25, 10, 10);
	$cr->set_source_rgb(0, 0, 0);
	$cr->fill();

	$cr->save();
	$cr->translate(30, 30);
	$cr->rotate(M_PI/4.0);
	$cr->rectangle(-5, -5, 10, 10);
	$cr->set_source_rgb(1, 0, 1);
	$cr->fill();
	$cr->restore();
	}


sub create_recording_surface
	{
	my ($bounded) = @_;

	my ($surface, $start, $size);

	if ($bounded)
		{
		$surface = Cairo::RecordingSurface->create('alpha', {x => 0, y => 0, width => RECORDING_SIZE, height => RECORDING_SIZE});
		($start, $size) = (0, RECORDING_SIZE);
		}
	else
		{
		$surface = Cairo::RecordingSurface->create('alpha', undef);
		($start, $size) = (RECORDING_SIZE/2, RECORDING_SIZE*2);
		}

	# Draw each tile instead of creating a cairo pattern to make size
	# of the emitted recording as large as possible.

	my ($cr) = Cairo::Context->create($surface);
	$cr->set_source_rgb(1, 1, 0);
	$cr->paint();
	my $ctm = $cr->get_matrix();
	for (my $y = $start; $y < $size; $y += TILE_SIZE)
		{
		for (my $x = $start; $x < $size; $x += TILE_SIZE)
			{
			draw_tile($cr);
			$cr->translate(TILE_SIZE, 0);
			}
		$ctm->translate(0, TILE_SIZE);
		$cr->set_matrix($ctm);
		}
	$cr = undef;

	$surface->set_mime_data($surface->MIME_TYPE_UNIQUE_ID, $bounded ? 'recording bounded' : 'recording unbounded');
	if ($surface->status() ne 'success')
		{
		say $surface->status();
		die;
		}

	return $surface;
	}

# Draw @source scaled to fit @rect and clipped to a rectangle
# @clip_margin units smaller on each side.  @rect will be stroked
# with a solid line and the clip rect stroked with a dashed line.

sub draw_surface
	{
	my ($cr, $source, $rect, $clip_margin) = @_;
	my ($width, $height);

	my $type = $source->get_type();
	if ($type eq 'image')
		{
		$width = $source->get_width();
		$height = $source->get_height();
		}
	elsif (defined(my $extents = $source->get_extents()))
		{
		$width = $$extents{width};
		$height = $$extents{height};
		}
	else
		{
		$width = RECORDING_SIZE;
		$height = RECORDING_SIZE;
		}

	$cr->save();
	$cr->rectangle($$rect{x}, $$rect{y}, $$rect{width}, $$rect{height});
	$cr->stroke();
	$cr->rectangle($$rect{x}+$clip_margin, $$rect{y}+$clip_margin, $$rect{width}-$clip_margin*2, $$rect{height}-$clip_margin*2);
	$cr->set_dash(0, 2, 2);
	$cr->stroke_preserve();
	$cr->clip();

	$cr->translate($$rect{x}, $$rect{y});
	$cr->scale($$rect{width}/$width, $$rect{height}/$height);
	$cr->set_source_surface($source, 0, 0);
	$cr->paint();

	$cr->restore();
	}


sub draw_pages
	{
	my ($surface) = @_;

	my $cr = Cairo::Context->create($surface);

	# Draw the image and recording surface on each page. The sources
	# are clipped starting with a small clip area on the first page
	# and increasing to the source size on last page to ensure the
	# embedded source is not clipped to the area used on the first
	# page.
	#
	# The sources are created each time they are used to ensure
	# CAIRO_MIME_TYPE_UNIQUE_ID is tested.

	for (my $i=0; $i<NUM_PAGES; $i++)
		{
		my $clip_margin = (NUM_PAGES-$i-1)*5;

		my $source = create_image_surface();
		draw_surface($cr, $source, {x => 25, y => 25, width => 100, height => 100,}, $clip_margin);
		$source = undef;

		$source = create_recording_surface_with_mime_jpg();
		draw_surface($cr, $source, {x => 150, y => 25, width => 100, height => 100,}, $clip_margin);
		$source = undef;

		$source = create_recording_surface(1);
		draw_surface($cr, $source, {x => 25, y => 150, width => 100, height => 100,}, $clip_margin);
		$source = undef;

		$source = create_recording_surface(0);
		draw_surface($cr, $source, {x => 150, y => 150, width => 100, height => 100,}, $clip_margin);
		$source = undef;	# REQUIRED!

		$cr->show_page();
		}

	$cr = undef;
	}




my $surface = Cairo::PdfSurface->create(OUTPUT_FILENAME, WIDTH, HEIGHT);
if ($surface->status() ne 'success')
	{
	say $surface->status();
	die;
	}
draw_pages($surface);
$surface->finish();

0;
