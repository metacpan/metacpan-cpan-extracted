#! /usr/bin/perl

# Adapted and translated to Perl from the file test/pdf-tagged-test.c in the
# Cairo (version 1.17.3) source repository by Adrian Johnson <ajohnson@redneon.com>.


use strict;
use warnings;
use Cairo;

use feature 'say';


# This test checks PDF with
# - tagged text
# - hyperlinks
# - document outline
# - metadata
# - thumbnails
# - page labels


use constant
	{
	FILENAME		=> 'pdf-tagged-text.pl.pdf',

	PAGE_WIDTH		=> 595,
	PAGE_HEIGHT		=> 842,

	HEADING1_SIZE		=> 16,
	HEADING2_SIZE		=> 14,
	HEADING3_SIZE		=> 12,
	TEXT_SIZE		=> 12,
	HEADING_HEIGHT		=> 50,
	MARGIN			=> 50,
	};


my @contents =
	(
	[ 0, "Chapter 1",     1 ],
	[ 1, "Section 1.1",   4 ],
	[ 2, "Section 1.1.1", 3 ],
	[ 1, "Section 1.2",   2 ],
	[ 2, "Section 1.2.1", 4 ],
	[ 2, "Section 1.2.2", 4 ],
	[ 1, "Section 1.3",   2 ],
	[ 0, "Chapter 2",     1 ],
	[ 1, "Section 2.1",   4 ],
	[ 2, "Section 2.1.1", 3 ],
	[ 1, "Section 2.2",   2 ],
	[ 2, "Section 2.2.1", 4 ],
	[ 2, "Section 2.2.2", 4 ],
	[ 1, "Section 2.3",   2 ],
	[ 0, "Chapter 3",     1 ],
	[ 1, "Section 3.1",   4 ],
	[ 2, "Section 3.1.1", 3 ],
	[ 1, "Section 3.2",   2 ],
	[ 2, "Section 3.2.1", 4 ],
	[ 2, "Section 3.2.2", 4 ],
	[ 1, "Section 3.3",   2 ],
	);

my @level_data =
	(
	[HEADING1_SIZE, 'H1', ['bold', 'open'],],
	[HEADING2_SIZE, 'H2', [],],
	[HEADING3_SIZE, 'H3', ['italic'],],
	);

my @ipsum_lorem = split(' ', "Lorem ipsum dolor sit amet, consectetur adipiscing"
	. " elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
	. " Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi"
	. " ut aliquip ex ea commodo consequat. Duis aute irure dolor in"
	. " reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla"
	. " pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa"
	. " qui officia deserunt mollit anim id est laborum.");

my @roman_numerals = ( "i", "ii", "iii", "iv", "v", );


my @paragraph_text;
my $paragraph_height = 0;
my $line_height = 0;
my $y_pos = 0;
my @outline_parents;
my $page_num = 0;


sub layout_paragraph
	{
	my ($cr) = @_;

	$cr->select_font_face('Serif', 'normal', 'normal');
	$cr->set_font_size(TEXT_SIZE);

	my $font_extents = $cr->font_extents();
	$line_height = $$font_extents{height};

	my $curr = $ipsum_lorem[0];
	foreach (@ipsum_lorem[1..$#ipsum_lorem])
		{
		my $next = join(' ', $curr, $_);
		my $text_extents = $cr->text_extents($next);
		if ($$text_extents{width} + 2*MARGIN > PAGE_WIDTH)
			{
			push @paragraph_text, $curr;
			$next = $_;
			}
		$curr = $next;
		}
	if ($curr ne '')
		{
		push @paragraph_text, $curr;
		}

	$paragraph_height = $line_height * (scalar @paragraph_text + 1);
	}


sub draw_paragraph
	{
	my ($cr) = @_;

	$cr->select_font_face('Serif', 'normal', 'normal');
	$cr->set_font_size(TEXT_SIZE);

	$cr->tag_begin('P', '');
	foreach (@paragraph_text)
		{
		$cr->move_to(MARGIN, $y_pos);
		$cr->show_text($_);
		$y_pos += $line_height;
		}
	$cr->tag_end('P');

	$y_pos += $line_height;
	}


sub draw_page_num
	{
	my ($cr, $prefix, $num) = @_;

	my $buf = ''
		. (defined $prefix) ? $prefix : ''
		. ($num) ? $num : '';

	$cr->save();

	$cr->select_font_face('Sans', 'normal', 'normal');
	$cr->set_font_size(12);

	$cr->move_to(PAGE_WIDTH/2, PAGE_HEIGHT - MARGIN);
	$cr->show_text($buf);

	$cr->restore();

	$cr->get_target()->set_page_label($buf);
	}


sub draw_contents
	{
	my ($cr, $section) = @_;

	if ($y_pos + HEADING_HEIGHT + MARGIN > PAGE_HEIGHT)
		{
		$cr->show_page();
		draw_page_num($cr, $roman_numerals[$page_num++], 0);
		$y_pos = MARGIN;
		}

	$cr->move_to(MARGIN, $y_pos);

	$cr->select_font_face('Sans', 'normal', 'normal');
	$cr->set_font_size($level_data[$$section[0]]->[0]);

	$cr->save();
	$cr->set_source_rgb(0, 0, 1);

	$cr->tag_begin('TOCI', '');
	$cr->tag_begin('Reference', '');
	$cr->tag_begin(Cairo::TAG_LINK, "dest='".$$section[1]."'");
	$cr->show_text($$section[1]);
	$cr->tag_end(Cairo::TAG_LINK);
	$cr->tag_end('Reference');
	$cr->tag_end('TOCI');

	$cr->restore();

	$y_pos += HEADING_HEIGHT;
	}


sub draw_section
	{
	my ($cr, $section) = @_;

	my $parent;

	if ($$section[0] == 0)
		{
		$cr->show_page();
		draw_page_num($cr, undef, $page_num++);
		$y_pos = MARGIN;

		$parent = $cr->get_target->OUTLINE_ROOT;
		}
	else
		{
		if ($y_pos + HEADING_HEIGHT + $paragraph_height + MARGIN > PAGE_HEIGHT)
			{
			$cr->show_page();
			draw_page_num($cr, undef, $page_num++);
			$y_pos = MARGIN;
			}

		$parent = $outline_parents[$$section[0]-1];
		}

	$cr->tag_begin('Sect', '');

	$cr->select_font_face('Sans', 'normal', 'bold');
	$cr->set_font_size($level_data[$$section[0]]->[0]);

	$cr->move_to(MARGIN, $y_pos);

	$cr->tag_begin($level_data[$$section[0]]->[1], '');
	$cr->tag_begin(Cairo::TAG_DEST, "name='".$$section[1]."'");
	$cr->show_text($$section[1]);
	$cr->tag_end(Cairo::TAG_DEST);
	$cr->tag_end($level_data[$$section[0]]->[1]);

	$y_pos += HEADING_HEIGHT;
	$outline_parents[$$section[0]] = $cr->get_target()->add_outline($parent, $$section[1], "dest='".$$section[1]."'", $level_data[$$section[0]]->[2]);

	for (my $i=0; $i<$$section[2]; $i++)
		{
		if ($y_pos + $paragraph_height + MARGIN > PAGE_HEIGHT)
			{
			$cr->show_page();
			draw_page_num($cr, undef, $page_num++);
			$y_pos = MARGIN;
			}
		draw_paragraph($cr);
		}

	$cr->tag_end('Sect');
	}


sub draw_cover
	{
	my ($cr) = @_;

	$cr->select_font_face("Sans", 'normal', 'bold');
	$cr->set_font_size(16);

	$cr->move_to(PAGE_WIDTH/3, PAGE_HEIGHT/2);

	$cr->tag_begin("Span", '');
	$cr->show_text("PDF Features Test");
	$cr->tag_end("Span");

	draw_page_num($cr, "cover", 0);
	}


sub create_document
	{
	my ($surface, $cr) = @_;

	layout_paragraph($cr);

	$surface->set_thumbnail_size(PAGE_WIDTH/10, PAGE_HEIGHT/10);

	$surface->set_metadata('title', "PDF Features Test");
	$surface->set_metadata('author', "cairo test suite");
	$surface->set_metadata('subject', "cairo test");
	$surface->set_metadata('keywords', "tags, links, outline, page labels, metadata, thumbnails");
	$surface->set_metadata('creator', "pdf-features");
	$surface->set_metadata('create-date', "2016-01-01T12:34:56+10:30");
	$surface->set_metadata('mod-date', "2016-06-21T05:43:21Z");

	$cr->tag_begin("Document", '');

	draw_cover($cr);
	$surface->add_outline($surface->OUTLINE_ROOT, 'Cover', 'page=1', ['bold']);
	$cr->show_page();

	$page_num = 0;
	draw_page_num($cr, $roman_numerals[$page_num++], 0);
	$y_pos = MARGIN;

	$surface->add_outline($surface->OUTLINE_ROOT, "Contents", "dest='TOC'", ['bold']);

	$cr->tag_begin(Cairo::TAG_DEST, "name='TOC' internal");
	$cr->tag_begin("TOC", '');

	foreach (@contents)
		{
		draw_contents($cr, $_);
		}

	$cr->tag_end("TOC");
	$cr->tag_end(Cairo::TAG_DEST);

	$page_num = 1;
	foreach (@contents)
		{
		draw_section($cr, $_);
		}

	$cr->tag_end("Document");
	}


my $surface = Cairo::PdfSurface->create(FILENAME, PAGE_WIDTH, PAGE_HEIGHT);

my $cr = Cairo::Context->create($surface);
create_document($surface, $cr);

my $status = $cr->status();
$cr = undef;
$surface->finish();
my $status2 = $surface->status();
if ($status ne 'success')
	{
	$status = $status2;
	}

$surface = undef;
if ($status ne 'success')
	{
	say "Failed to create pdf surface: $status";
	die;
	}

0;
