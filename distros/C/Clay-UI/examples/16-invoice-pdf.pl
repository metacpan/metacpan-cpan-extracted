#!/usr/bin/env perl

# 16-invoice-pdf.pl - A multi-page A4 invoice, drawn with PDF::Builder.
#
# A template class turns an invoice data hash into a Clay::UI widget tree
# (letterhead, addresses, line-item table, totals, payment terms, footer).
# Clay lays the page out in PDF points, real font metrics from PDF::Builder
# measure the text, and a small renderer turns the render commands into PDF
# drawing operators. The key lesson is pagination: lay the whole table out
# once, read every row's height back with bounding_box, split the rows into
# pages so no row is cut, then lay out and draw every page on its own.
# Writes the PDF to the path given as first argument (out.pdf in the
# current directory by default); a second argument sets the number of
# line items (45 by default).
#
# Shows:
#   - A4 pages as Clay layout units (595 x 842 points), with Clay's
#     downward y axis flipped into PDF's upward one in the renderer
#   - text measured with PDF core font metrics, wrapped item descriptions
#     that give the table rows different heights
#   - a line-item table with a styled header row, zebra rows and
#     right-aligned numeric columns, and a totals block on the same columns
#   - measuring row heights with a full layout pass and paginating on them:
#     no row is cut, the table header repeats, totals go on the last page
#   - a custom element (the logo) drawn by a callback and clipped by its
#     parent (scissor commands become a PDF clipping path)
#   - a reusable renderer for RECTANGLE (with corner radius), BORDER (per
#     side), TEXT, CUSTOM and SCISSOR_START / SCISSOR_END commands
#
# Features: Clay::UI, Clay::UI::Box, Clay::UI::Text, Clay::UI::Grid, Clay::UI::Grid::Cell, share_columns_with, append_row, bounding_box, measure_text, contribute_custom, contribute_clip, customData, CLAY_TEXT_WRAP_WORDS, child_alignment, CLAY_ALIGN_X_RIGHT, sizing_fixed, sizing_fit, sizing_grow, background_color, border_width, corner_radius, letter_spacing, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_TEXT, CLAY_RENDER_COMMAND_TYPE_CUSTOM, CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END
#
# Requires: PDF::Builder (uses its built-in core fonts, no font files).
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/16-invoice-pdf.pl [out.pdf] [item_count]

use v5.22;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use PDF::Builder;

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Text;
use Clay::UI::Grid;
use Clay::UI::Grid::Cell;

# ---- Page geometry and fonts ----

# One Clay layout unit is one PDF point (1/72 inch), so an A4 page is a
# 595 x 842 layout.
use constant {
	PAGE_WIDTH  => 595,
	PAGE_HEIGHT => 842,

	# The full-table measuring pass needs a page tall enough for every row.
	MEASURE_PAGE_HEIGHT => 100_000,

	# Clay only passes a font_id around; the measure callback and the
	# renderer map it to a PDF::Builder font object.
	FONT_REGULAR => 0,
	FONT_BOLD    => 1,

	# Height of one text line as a multiple of the font size.
	LINE_HEIGHT => 1.25,

	# The logo is a custom element; customData selects its drawing callback.
	DRAWING_LOGO => 1,
};

# ---- Widget classes ----

class Invoice::Box  :strict(params) :does(Clay::UI::Box)  {}
class Invoice::Text :strict(params) :does(Clay::UI::Text) {}
class Invoice::Grid :strict(params) :does(Clay::UI::Grid) {}

# A box that clips its children. Clay::UI passes a clip configuration from
# any widget on to Clay, which then wraps the children's render commands in
# SCISSOR_START / SCISSOR_END (see Clay::UI, NOTES).
class Invoice::ClipBox :strict(params) :does(Clay::UI::Box) {
	method contribute_clip ($config) {
		$config->{clip} = { horizontal => 1, vertical => 1 };
		return;
	}
}

# A custom element: Clay lays it out like a box and emits a CUSTOM render
# command carrying custom_data, an integer the renderer uses to find the
# code that draws it.
class Invoice::Drawing :strict(params) :does(Clay::UI::Box) {
	field $custom_data :param;

	method contribute_custom ($config) {
		$config->{custom} = { custom_data => $custom_data };
		return;
	}
}

# ---- The invoice template ----

# Turns an invoice data hash into the widget tree of one page. The same
# template builds every page; the arguments of build_page decide which
# rows of the line-item table and which closing parts the page shows.
class Invoice::Template :strict(params) {
	# A class block is a fresh package: import what it uses here.
	use Clay::XS qw(:all);

	field $invoice :param;

	my %COLOR = (
		ink        => [33,  37,  41,  255],
		muted      => [108, 117, 125, 255],
		accent     => [31,  78,  121, 255],
		on_accent  => [255, 255, 255, 255],
		zebra      => [243, 246, 249, 255],
		rule       => [214, 220, 226, 255],
	);

	my $FONT_REGULAR = main::FONT_REGULAR;
	my $FONT_BOLD    = main::FONT_BOLD;

	# Gap between the sections of the page body (letterhead, addresses,
	# table, closing block).
	my $SECTION_GAP = 18;

	my @COLUMNS = (
		{ title => 'Pos.',         numeric => 1 },
		{ title => 'Description',  numeric => 0 },
		{ title => 'Quantity',     numeric => 1 },
		{ title => 'Unit price',   numeric => 1 },
		{ title => 'Amount (EUR)', numeric => 1 },
	);
	use constant DESCRIPTION_COLUMN => 1;

	# build_page(%args) returns the page's root widget together with the
	# widgets the paginator measures (see "Measure" in the main program).
	#
	#   page_number, page_count  for the footer and the letterhead choice
	#   page_height              PAGE_HEIGHT, or a tall page for measuring
	#   with_table               show the line-item table on this page
	#   rows                     arrayref of item indices the table shows
	#   with_closing             show totals and payment terms
	#   column_widths            undef: columns fit their content (column
	#                            pass); arrayref: fixed width per column
	method build_page (%args) {
		my %parts = (rows => [], header_cells => []);
		my @sections;

		push @sections, $args{page_number} == 1
			? ($self->_letterhead, $self->_address_row, $self->_intro)
			: $self->_continued_letterhead;

		if ($args{with_table}) {
			$parts{table} = $self->_item_table($args{rows}, $args{column_widths}, \%parts);
			push @sections, $parts{table};
		}
		if ($args{with_closing}) {
			$parts{closing} = $self->_closing_block($parts{columns}, $args{column_widths});
			push @sections, $parts{closing};
		}

		# The body grows to fill the page above the footer, so its bottom
		# edge is the lowest point any row may reach.
		$parts{body} = $self->_box(
			id     => 'body',
			layout => {
				sizing           => { width => sizing_grow(), height => sizing_grow() },
				layout_direction => CLAY_TOP_TO_BOTTOM,
				child_gap        => $SECTION_GAP,
			},
		);
		$parts{body}->add_child(@sections);

		$parts{root} = $self->_box(
			id     => 'page',
			layout => {
				sizing           => { width => sizing_fixed(main::PAGE_WIDTH), height => sizing_fixed($args{page_height}) },
				padding          => { left => 48, right => 48, top => 40, bottom => 30 },
				layout_direction => CLAY_TOP_TO_BOTTOM,
				child_gap        => 12,
			},
			background_color => [255, 255, 255, 255],
		);
		$parts{root}->add_child($parts{body}, $self->_footer($args{page_number}, $args{page_count}));
		return \%parts;
	}

	# ---- Small widget helpers ----

	method _box (%args) {
		return Invoice::Box->new(%args);
	}

	method _text ($text, %style) {
		my $font_id = delete $style{bold} ? $FONT_BOLD : $FONT_REGULAR;
		my $color   = $COLOR{ delete $style{color} // 'ink' };
		return Invoice::Text->new(
			text       => $text,
			font_id    => $font_id,
			font_size  => 9,
			text_color => $color,
			%style,
		);
	}

	method _wrapped_text ($text, %style) {
		return $self->_text($text, wrap_mode => CLAY_TEXT_WRAP_WORDS, %style);
	}

	method _spacer {
		return $self->_box(layout => { sizing => { width => sizing_grow() } });
	}

	method _column ($gap, @children) {
		my $column = $self->_box(layout => { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => $gap });
		$column->add_child(@children);
		return $column;
	}

	# A small-caps style label above a block ("BILL TO").
	method _caption ($text) {
		return $self->_text(uc $text, bold => 1, font_size => 7, color => 'muted', letter_spacing => 1);
	}

	# The logo: a rounded square that clips the custom drawing inside it.
	# The drawing paints a sun larger than the square; the scissor commands
	# of the clip box cut it off at the square's edges.
	method _logo ($size) {
		my $frame = Invoice::ClipBox->new(
			layout           => { sizing => { width => sizing_fixed($size), height => sizing_fixed($size) } },
			background_color => $COLOR{accent},
			corner_radius    => $size / 5,
		);
		$frame->add_child(Invoice::Drawing->new(
			custom_data => main::DRAWING_LOGO,
			layout      => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		));
		return $frame;
	}

	# ---- Letterheads ----

	method _letterhead {
		my $seller = $invoice->{seller};
		my $letterhead = $self->_box(
			layout => {
				sizing          => { width => sizing_grow() },
				padding         => { bottom => 14 },
				child_gap       => 12,
				child_alignment => { y => CLAY_ALIGN_Y_CENTER },
			},
			border_color => $COLOR{accent},
			border_width => { top => 0, left => 0, right => 0, bottom => 2, between_children => 0 },
		);
		$letterhead->add_child(
			$self->_logo(44),
			$self->_column(2,
				$self->_text($seller->{name}, bold => 1, font_size => 15),
				$self->_text($seller->{tagline}, font_size => 8, color => 'muted'),
			),
			$self->_spacer,
			$self->_text('INVOICE', bold => 1, font_size => 24, color => 'accent', letter_spacing => 3),
		);
		return $letterhead;
	}

	method _continued_letterhead {
		my $letterhead = $self->_box(
			layout => {
				sizing          => { width => sizing_grow() },
				padding         => { bottom => 10 },
				child_gap       => 10,
				child_alignment => { y => CLAY_ALIGN_Y_CENTER },
			},
			border_color => $COLOR{accent},
			border_width => { top => 0, left => 0, right => 0, bottom => 2, between_children => 0 },
		);
		$letterhead->add_child(
			$self->_logo(26),
			$self->_text($invoice->{seller}{name}, bold => 1, font_size => 11),
			$self->_spacer,
			$self->_text("Invoice $invoice->{number} (continued)", font_size => 9, color => 'muted'),
		);
		return $letterhead;
	}

	# ---- Addresses and invoice data ----

	method _address_row {
		my ($seller, $recipient) = @$invoice{qw(seller recipient)};

		my $sender_line = $self->_box(
			layout       => { padding => { bottom => 2 } },
			border_color => $COLOR{rule},
			border_width => { top => 0, left => 0, right => 0, bottom => 1, between_children => 0 },
		);
		$sender_line->add_child($self->_text(join(' - ', $seller->{name}, $seller->{address}->@*), font_size => 7, color => 'muted'));

		my $address = $self->_column(3,
			$sender_line,
			$self->_box(layout => { sizing => { height => sizing_fixed(6) } }),
			$self->_caption('Bill to'),
			$self->_text($recipient->{name}, bold => 1, font_size => 10),
			map { $self->_text($_) } $recipient->{address}->@*,
		);

		my $row = $self->_box(layout => { sizing => { width => sizing_grow() } });
		$row->add_child($address, $self->_spacer, $self->_invoice_data);
		return $row;
	}

	# Number and dates as a two-column grid: labels on the left, values
	# right-aligned so their right edges line up with the page margin.
	method _invoice_data {
		my $grid = Invoice::Grid->new(id => 'invoice_data', row_gap => 3, cell_gap => 16);
		for my $entry ($invoice->{data}->@*) {
			my ($label, $value) = @$entry;
			my $value_cell = Clay::UI::Grid::Cell->new(layout => { child_alignment => { x => CLAY_ALIGN_X_RIGHT } });
			$value_cell->add_child($self->_text($value, bold => 1));
			$grid->append_row([ $self->_text($label, color => 'muted'), $value_cell ]);
		}
		return $grid;
	}

	method _intro {
		return $self->_wrapped_text($invoice->{intro}, font_size => 10);
	}

	# ---- The line-item table ----

	# A cell's width. Without column_widths (the column pass, see
	# measure_columns) every column fits its content except the
	# description, which is 1 point wide and later gets whatever the other
	# columns leave (not 0 points: Clay reads a zero maximum as "no limit",
	# so sizing_fixed(0) would fit the unwrapped text). With column_widths
	# every column has a fixed width, so the text wraps the same way on
	# every page as in the pass that measured the rows.
	sub _cell_width ($column, $column_widths) {
		return sizing_fixed($column_widths->[$column]) if $column_widths;
		return $column == DESCRIPTION_COLUMN ? sizing_fixed(1) : sizing_fit();
	}

	method _cell (%args) {
		my $column = $COLUMNS[ $args{column} ];
		my $cell = Clay::UI::Grid::Cell->new(
			layout => {
				sizing           => { width => _cell_width($args{column}, $args{column_widths}) },
				padding          => $args{padding},
				child_gap        => 2,
				layout_direction => CLAY_TOP_TO_BOTTOM,
				child_alignment  => { x => $column->{numeric} ? CLAY_ALIGN_X_RIGHT : CLAY_ALIGN_X_LEFT },
			},
			$args{style}->%*,
		);
		$cell->add_child($args{content}->@*);
		return $cell;
	}

	# The table is two grids sharing their columns: a header grid painted
	# in one piece by its own background (separate cell backgrounds would
	# show hairline seams between them in some PDF viewers), and the body
	# grid with the item rows. Every page gets a fresh header grid, so the
	# header repeats. Returns the box holding both; the header grid goes to
	# $parts->{columns}, the grid the totals share their columns with.
	method _item_table ($rows, $column_widths, $parts) {
		my $header = Invoice::Grid->new(
			id               => 'items_header',
			layout           => { sizing => { width => sizing_grow() } },
			background_color => $COLOR{accent},
		);
		my @header_cells = map {
			$self->_cell(
				column        => $_,
				column_widths => $column_widths,
				padding       => { left => 6, right => 6, top => 6, bottom => 6 },
				style         => {},
				content       => [ $self->_text($COLUMNS[$_]{title}, bold => 1, font_size => 8, color => 'on_accent') ],
			)
		} 0 .. $#COLUMNS;
		$header->append_row(\@header_cells);
		$parts->{header_cells} = \@header_cells;
		$parts->{columns}      = $header;

		my $body = Invoice::Grid->new(
			id                 => 'items',
			layout             => { sizing => { width => sizing_grow() } },
			share_columns_with => $header,
		);
		for my $index (@$rows) {
			my @cells = $self->_item_cells($invoice->{items}[$index], $index, $column_widths);
			$body->append_row(\@cells);
			push $parts->{rows}->@*, $cells[0];
		}

		my $table = $self->_box(layout => { sizing => { width => sizing_grow() }, layout_direction => CLAY_TOP_TO_BOTTOM });
		$table->add_child($header, $body);
		return $table;
	}

	method _item_cells ($item, $index, $column_widths) {
		# Zebra stripes follow the item number, not the position on the
		# page, so they continue across page breaks.
		my %style = (
			$index % 2 ? (background_color => $COLOR{zebra}) : (),
			border_color => $COLOR{rule},
			border_width => { top => 0, left => 0, right => 0, bottom => 1, between_children => 0 },
		);
		my @description = ($self->_wrapped_text($item->{title}));
		push @description, $self->_wrapped_text($item->{detail}, font_size => 8, color => 'muted')
			if defined $item->{detail};

		my @content = (
			[ $self->_text($index + 1, color => 'muted') ],
			\@description,
			[ $self->_text("$item->{quantity} $item->{unit}") ],
			[ $self->_text(main::format_money($item->{unit_price})) ],
			[ $self->_text(main::format_money($item->{amount})) ],
		);
		return map {
			$self->_cell(
				column        => $_,
				column_widths => $column_widths,
				padding       => { left => 6, right => 6, top => 5, bottom => 5 },
				style         => \%style,
				content       => $content[$_],
			)
		} 0 .. $#COLUMNS;
	}

	# ---- Totals, payment terms ----

	method _closing_block ($columns, $column_widths) {
		my $closing = $self->_box(
			id     => 'closing',
			layout => {
				sizing           => { width => sizing_grow() },
				layout_direction => CLAY_TOP_TO_BOTTOM,
				child_gap        => $SECTION_GAP,
			},
		);
		$closing->add_child($self->_totals($columns, $column_widths), $self->_payment_terms);
		return $closing;
	}

	# The totals are one more grid on the item table's columns, so the
	# labels sit in the "Unit price" column and the sums right below the
	# amounts. On a page without a table (the totals did not fit below the
	# last rows) there is no grid to share with; the fixed column widths
	# keep the same alignment.
	method _totals ($columns, $column_widths) {
		my $totals = Invoice::Grid->new(
			id     => 'totals',
			layout => { sizing => { width => sizing_grow() } },
			$columns ? (share_columns_with => $columns) : (),
		);
		my @lines = (
			[ 'Subtotal',                         $invoice->{subtotal}, 0 ],
			[ "VAT $invoice->{vat_percent} %",    $invoice->{vat},      0 ],
			[ "Total due ($invoice->{currency})", $invoice->{total},    1 ],
		);
		for my $line (@lines) {
			my ($label, $amount, $is_total) = @$line;
			# The total gets a rule above it; it is drawn as one strip per cell.
			my %text_style = $is_total ? (bold => 1, font_size => 11, color => 'accent') : ();
			my %cell_style = $is_total
				? (border_color => $COLOR{accent}, border_width => { top => 2, left => 0, right => 0, bottom => 0, between_children => 0 })
				: ();
			my $padding    = { left => 6, right => 6, top => $is_total ? 8 : 4, bottom => 2 };
			my @empty = map {
				$self->_cell(column => $_, column_widths => $column_widths, padding => $padding, style => {}, content => [])
			} 0 .. 2;
			$totals->append_row([
				@empty,
				$self->_cell(
					column => 3, column_widths => $column_widths, padding => $padding, style => \%cell_style,
					content => [ $self->_text($label, %text_style, $is_total ? () : (color => 'muted')) ],
				),
				$self->_cell(
					column => 4, column_widths => $column_widths, padding => $padding, style => \%cell_style,
					content => [ $self->_text(main::format_money($amount), %text_style) ],
				),
			]);
		}
		return $totals;
	}

	method _payment_terms {
		my $panel = $self->_box(
			layout => {
				sizing    => { width => sizing_grow() },
				padding   => padding_all(12),
				child_gap => 24,
			},
			background_color => $COLOR{zebra},
			corner_radius    => 4,
		);
		my $terms = $self->_box(layout => { sizing => { width => sizing_grow() }, layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 4 });
		$terms->add_child(
			$self->_caption('Payment terms'),
			map { $self->_wrapped_text($_) } $invoice->{payment_terms}->@*,
		);
		my $bank = $self->_column(4,
			$self->_caption('Bank details'),
			map { $self->_text($_) } $invoice->{bank}->@*,
		);
		$panel->add_child($terms, $bank);
		return $panel;
	}

	# ---- Footer ----

	method _footer ($page_number, $page_count) {
		my $footer = $self->_box(
			layout => {
				sizing          => { width => sizing_grow() },
				padding         => { top => 8 },
				child_alignment => { y => CLAY_ALIGN_Y_CENTER },
			},
			border_color => $COLOR{rule},
			border_width => { top => 1, left => 0, right => 0, bottom => 0, between_children => 0 },
		);
		$footer->add_child(
			$self->_text($invoice->{seller}{legal}, font_size => 7, color => 'muted'),
			$self->_spacer,
			$self->_text("Page $page_number / $page_count", font_size => 8, color => 'muted'),
		);
		return $footer;
	}
}

# ---- Invoice data ----

sub format_money ($cents) {
	my $text = sprintf '%d.%02d', int($cents / 100), $cents % 100;
	1 while $text =~ s/^(\d+)(\d{3})/$1,$2/;
	return $text;
}

# Deterministic line items for the service period, September 2026
# (calendar weeks 36 to 40). Monthly services come first, billed once
# for the month; the other services are billed per week. Within a week
# the services rotate, a week has at most one item of each daily service,
# and every hourly item names its own ticket, so no week lists the same
# item twice. Some items carry a long detail text
# that wraps over several lines.
sub generate_items ($count) {
	my @monthly_services = (
		[ 'Managed database', 24_900, 'PostgreSQL cluster with daily backups, point-in-time recovery and around-the-clock monitoring.' ],
		[ 'Support retainer', 45_000, undef ],
	);
	my @weekly_services = (
		[ 'Backend development',  'hours',   9_500, 'API endpoints for the order import, including validation of partner payloads and retry handling for failed deliveries.' ],
		[ 'Frontend development', 'hours',   8_800, undef ],
		[ 'Code review',          'hours',   7_500, 'Review of pull requests for the reporting module.' ],
		[ 'Project management',   'hours',   7_000, undef ],
		[ 'UX workshop',          'days',  120_000, 'Remote workshop with stakeholders, including preparation, moderation and a written summary of all decisions taken.' ],
		[ 'Security audit',       'days',  135_000, 'Dependency audit and penetration test of the customer portal; findings delivered as a prioritised report.' ],
	);
	my ($first_week, $week_count) = (36, 5);

	my @hourly_services = grep { $_->[1] eq 'hours' } @weekly_services;
	my $monthly_count   = $count < @monthly_services ? $count : @monthly_services;

	my @items;
	for my $service (@monthly_services[ 0 .. $monthly_count - 1 ]) {
		my ($name, $unit_price, $detail) = @$service;
		push @items, {
			title      => "$name, September 2026",
			detail     => $detail,
			quantity   => 1,
			unit       => 'month',
			unit_price => $unit_price,
			amount     => $unit_price,
		};
	}

	my $weekly_count = $count - @items;
	my %items_in_week;
	my $next_ticket = 1040;
	for my $index (0 .. $weekly_count - 1) {
		my $week     = $first_week + int($index * $week_count / $weekly_count);
		my $position = $items_in_week{$week}++;
		# Once every service had its turn this week, only hourly ones repeat.
		my $services = $position < @weekly_services ? \@weekly_services : \@hourly_services;
		my ($name, $unit, $unit_price, $detail) = $services->[ ($week + $position) % @$services ]->@*;
		my $quantity = $unit eq 'hours' ? 1 + ($index * 7) % 16 : 1 + $index % 3;
		my $ticket   = $unit eq 'hours' ? sprintf(', ticket NL-%d', $next_ticket++) : '';
		push @items, {
			title      => "$name, calendar week $week$ticket",
			detail     => $detail,
			quantity   => $quantity,
			unit       => $quantity == 1 ? substr($unit, 0, -1) : $unit,
			unit_price => $unit_price,
			amount     => $quantity * $unit_price,
		};
	}
	return \@items;
}

sub build_invoice ($item_count) {
	my $items       = generate_items($item_count);
	my $vat_percent = 19;
	my $subtotal    = 0;
	$subtotal += $_->{amount} for @$items;
	my $vat = int(($subtotal * $vat_percent + 50) / 100);    # cents, rounded half up

	return {
		number   => 'INV-2026-0042',
		currency => 'EUR',
		seller   => {
			name    => 'Nordlicht Software GmbH',
			tagline => 'Software development and operations',
			address => [ 'Hafenstraße 12', '20457 Hamburg', 'Germany' ],
			legal   => 'Managing director: Jana Petersen - Amtsgericht Hamburg HRB 123456 - VAT ID DE123456789',
		},
		recipient => {
			name    => 'Example Industries Ltd.',
			address => [ 'Attn. Accounts Payable', '221 Market Street', 'Manchester M1 1AA', 'United Kingdom' ],
		},
		data => [
			[ 'Invoice number', 'INV-2026-0042' ],
			[ 'Invoice date',   '2026-10-01' ],
			[ 'Service period', 'Sep 2026' ],
			[ 'Customer no.',   'C-10734' ],
			[ 'Due date',       '2026-10-31' ],
		],
		intro => 'Thank you for your order. As agreed in our framework contract of 12 March 2026, '
			. 'we invoice the following services delivered in September 2026:',
		items         => $items,
		subtotal      => $subtotal,
		vat_percent   => $vat_percent,
		vat           => $vat,
		total         => $subtotal + $vat,
		payment_terms => [
			'Please transfer the total amount within 30 days of the invoice date, quoting the invoice number INV-2026-0042.',
			'Questions about this invoice: billing@nordlicht.example',
		],
		bank => [ 'Hamburger Sparkasse', 'IBAN DE02 2005 0550 1234 5678 90', 'BIC HASPDEHHXXX' ],
	};
}

# ---- Renderer: Clay render commands to PDF operators ----

# Clay's y axis points down from the top of the page, PDF's points up
# from the bottom. Every box is converted once, to its lower-left corner
# in PDF coordinates.
sub pdf_rect ($bounding_box, $page_height) {
	my ($x, $y, $width, $height) = @$bounding_box{qw(x y width height)};
	return ($x, $page_height - $y - $height, $width, $height);
}

sub set_fill_color ($gfx, $color) {
	$gfx->fillcolor(map { $_ / 255 } @$color{qw(r g b)});
	return;
}

# A rectangle path with one radius per corner (Clay's cornerRadius),
# each corner approximated by a cubic Bezier curve.
sub rounded_rect_path ($gfx, $x, $y, $width, $height, $radius) {
	my $kappa = 0.5523;
	my $top   = $y + $height;
	my $right = $x + $width;
	my ($tl, $tr, $bl, $br) = @$radius{qw(topLeft topRight bottomLeft bottomRight)};

	$gfx->move($x + $tl, $top);
	$gfx->line($right - $tr, $top);
	$gfx->curve($right - $tr + $kappa * $tr, $top, $right, $top - $tr + $kappa * $tr, $right, $top - $tr);
	$gfx->line($right, $y + $br);
	$gfx->curve($right, $y + $br - $kappa * $br, $right - $br + $kappa * $br, $y, $right - $br, $y);
	$gfx->line($x + $bl, $y);
	$gfx->curve($x + $bl - $kappa * $bl, $y, $x, $y + $bl - $kappa * $bl, $x, $y + $bl);
	$gfx->line($x, $top - $tl);
	$gfx->curve($x, $top - $tl + $kappa * $tl, $x + $tl - $kappa * $tl, $top, $x + $tl, $top);
	$gfx->close;
	return;
}

sub has_corner_radius ($radius) {
	return grep { $_ > 0 } values %$radius;
}

sub draw_rectangle ($gfx, $cmd, $page_height) {
	my $data = $cmd->{renderData};
	return if $data->{backgroundColor}{a} == 0;
	my @rect = pdf_rect($cmd->{boundingBox}, $page_height);
	set_fill_color($gfx, $data->{backgroundColor});
	has_corner_radius($data->{cornerRadius})
		? rounded_rect_path($gfx, @rect, $data->{cornerRadius})
		: $gfx->rect(@rect);
	$gfx->fill;
	return;
}

# Each side is a filled strip inside the bounding box, as Clay draws
# borders inside the element. Rounded border corners are not drawn
# (this template uses none).
sub draw_border ($gfx, $cmd, $page_height) {
	my ($x, $y, $width, $height) = pdf_rect($cmd->{boundingBox}, $page_height);
	my $sides = $cmd->{renderData}{width};
	set_fill_color($gfx, $cmd->{renderData}{color});
	my @strips = (
		[ $sides->{top},    $x,                           $y + $height - $sides->{top}, $width,          $sides->{top} ],
		[ $sides->{bottom}, $x,                           $y,                           $width,          $sides->{bottom} ],
		[ $sides->{left},   $x,                           $y,                           $sides->{left},  $height ],
		[ $sides->{right},  $x + $width - $sides->{right}, $y,                          $sides->{right}, $height ],
	);
	for my $strip (@strips) {
		my ($side_width, @rect) = @$strip;
		next unless $side_width > 0;
		$gfx->rect(@rect);
		$gfx->fill;
	}
	return;
}

# Clay gives each line of text its own bounding box, one line high. The
# baseline goes where the glyphs (ascender to descender) sit centred in
# that box.
sub draw_text ($gfx, $cmd, $page_height, $fonts) {
	my $data = $cmd->{renderData};
	my $font = $fonts->{ $data->{fontId} } // die "render_to_pdf_page: no font for fontId $data->{fontId}\n";
	my $size = $data->{fontSize};
	my ($x, $y, undef, $height) = pdf_rect($cmd->{boundingBox}, $page_height);

	my $ascent   = $font->ascender / 1000 * $size;
	my $descent  = -$font->descender / 1000 * $size;
	my $baseline = $y + ($height - $ascent - $descent) / 2 + $descent;

	# Letter spacing (Tc) is graphics state that outlives the text object;
	# save / restore keeps it from leaking into the next text.
	$gfx->save;
	$gfx->textstart;
	$gfx->font($font, $size);
	$gfx->charspace($data->{letterSpacing}) if $data->{letterSpacing};
	set_fill_color($gfx, $data->{textColor});
	$gfx->translate($x, $baseline);
	$gfx->text($data->{stringContents});
	$gfx->textend;
	$gfx->restore;
	return;
}

sub draw_custom ($gfx, $cmd, $page_height, $drawings) {
	my $key  = $cmd->{renderData}{customData};
	my $draw = $drawings->{$key} // die "render_to_pdf_page: no drawing registered for customData $key\n";
	$draw->($gfx, pdf_rect($cmd->{boundingBox}, $page_height));
	return;
}

# A scissor region becomes a clipping path inside a saved graphics state;
# SCISSOR_END restores the state and with it the previous clip.
sub start_scissor ($gfx, $cmd, $page_height) {
	$gfx->save;
	$gfx->rect(pdf_rect($cmd->{boundingBox}, $page_height));
	$gfx->clip;
	$gfx->endpath;
	return;
}

# Draws one page's render commands onto a PDF::Builder page. $fonts maps
# Clay font ids to PDF::Builder font objects, $drawings maps the
# customData of custom elements to callbacks called with
# ($gfx, $x, $y, $width, $height) in PDF coordinates. Everything goes into
# one content stream, so the drawing order is the command order.
sub render_to_pdf_page ($commands, $page, $fonts, $drawings = {}) {
	my $page_height = ($page->mediabox)[3];
	my $gfx = $page->gfx;
	my %draw = (
		CLAY_RENDER_COMMAND_TYPE_RECTANGLE()     => sub ($cmd) { draw_rectangle($gfx, $cmd, $page_height) },
		CLAY_RENDER_COMMAND_TYPE_BORDER()        => sub ($cmd) { draw_border($gfx, $cmd, $page_height) },
		CLAY_RENDER_COMMAND_TYPE_TEXT()          => sub ($cmd) { draw_text($gfx, $cmd, $page_height, $fonts) },
		CLAY_RENDER_COMMAND_TYPE_CUSTOM()        => sub ($cmd) { draw_custom($gfx, $cmd, $page_height, $drawings) },
		CLAY_RENDER_COMMAND_TYPE_SCISSOR_START() => sub ($cmd) { start_scissor($gfx, $cmd, $page_height) },
		CLAY_RENDER_COMMAND_TYPE_SCISSOR_END()   => sub ($cmd) { $gfx->restore },
	);
	for my $cmd (@$commands) {
		my $handler = $draw{ $cmd->{commandType} }
			// die "render_to_pdf_page: unsupported render command type $cmd->{commandType}\n";
		$handler->($cmd);
	}
	return;
}

# The logo drawing: a sun rising behind the bottom edge, under two bands
# of light. The callback paints the whole sun and full-width bands; the
# frame's scissor cuts off everything outside the frame.
sub draw_logo ($gfx, $x, $y, $width, $height) {
	$gfx->fillcolor(244 / 255, 180 / 255, 60 / 255);
	$gfx->circle($x + $width / 2, $y, $width * 0.3);
	$gfx->fill;
	$gfx->fillcolor(1, 1, 1);
	for my $band (0.5, 0.68) {
		$gfx->rect($x - $width, $y + $height * $band, 3 * $width, $height * 0.07);
		$gfx->fill;
	}
	return;
}

# ---- Text measurement ----

# Widths come from the core font metrics: $font->width is the advance
# width at size 1, in points. Every line is LINE_HEIGHT times the font
# size high; the renderer centres the glyphs in that line.
sub make_measure_text ($fonts) {
	return sub ($text, $config, $userdata) {
		my $font = $fonts->{ $config->{fontId} } // die "measure_text: no font for fontId $config->{fontId}\n";
		my $size = $config->{fontSize};
		return {
			width  => $font->width($text) * $size + $config->{letterSpacing} * length($text),
			height => $size * LINE_HEIGHT,
		};
	};
}

# ---- Layout helper ----

sub lay_out ($parts, $page_height, $measure_text) {
	my $ui = Clay::UI->new(
		width        => PAGE_WIDTH,
		height       => $page_height,
		root         => $parts->{root},
		measure_text => $measure_text,
	);
	my $commands = $ui->render;
	return ($ui, $commands);
}

sub bottom_of ($box) {
	return $box->{y} + $box->{height};
}

# ---- Measure: lay the whole table out before paginating ----

# Pagination needs every row's height before any page is built, and a
# row's height depends on how its description wraps. Rather than
# predicting the wrapping, let Clay do it: build page 1 with ALL rows and
# the closing block on a page tall enough to hold them, lay it out, and
# read the result back with $ui->bounding_box. This takes two passes:
#
#   1. The column pass finds the column widths. The numeric columns fit
#      their widest cell (the totals share the columns, so their labels
#      count too); the description column gets what is left of the table
#      width. (A sizing_grow description column would wrap too, but the
#      pagination below needs the widths as numbers, so they are measured
#      once and fixed.)
#   2. The row pass lays the same page out again with those widths fixed
#      (sizing_fixed) and reads every row's height. The real pages use
#      the same fixed widths, so each row wraps exactly as it was
#      measured; with fitted columns a page holding only some rows could
#      size its columns differently and invalidate the heights.
sub measure_page_with_all_rows ($template, $item_count, $column_widths, $measure_text) {
	my $parts = $template->build_page(
		page_number   => 1,
		page_count    => 1,
		page_height   => MEASURE_PAGE_HEIGHT,
		with_table    => 1,
		rows          => [ 0 .. $item_count - 1 ],
		with_closing  => 1,
		column_widths => $column_widths,
	);
	my ($ui) = lay_out($parts, MEASURE_PAGE_HEIGHT, $measure_text);
	die "The measuring page is too short for $item_count items\n"
		if bottom_of($ui->bounding_box($parts->{closing})) > bottom_of($ui->bounding_box($parts->{body}));
	return ($ui, $parts);
}

sub measure_columns ($template, $item_count, $measure_text) {
	my ($ui, $parts) = measure_page_with_all_rows($template, $item_count, undef, $measure_text);
	# Whole points keep every cell edge on a whole point too, so adjacent
	# cell backgrounds meet without anti-aliasing seams in PDF viewers.
	my @widths = map { int($ui->bounding_box($_)->{width} + 0.999) } $parts->{header_cells}->@*;
	my $others = 0;
	$others += $widths[$_] for grep { $_ != Invoice::Template::DESCRIPTION_COLUMN } 0 .. $#widths;
	$widths[Invoice::Template::DESCRIPTION_COLUMN] = $ui->bounding_box($parts->{table})->{width} - $others;
	return \@widths;
}

sub measure_rows ($template, $item_count, $column_widths, $measure_text) {
	my ($ui, $parts) = measure_page_with_all_rows($template, $item_count, $column_widths, $measure_text);
	my @rows     = map { $ui->bounding_box($_) } $parts->{rows}->@*;
	my $header   = $ui->bounding_box($parts->{header_cells}[0]);
	my $closing  = $ui->bounding_box($parts->{closing});
	my $last_row = @rows ? $rows[-1] : $header;

	return {
		column_widths  => $column_widths,
		row_heights    => [ map { $_->{height} } @rows ],
		first_rows_top => bottom_of($header),
		closing_height => $closing->{height},
		closing_gap    => $closing->{y} - bottom_of($last_row),
	};
}

# A continuation page with an empty table tells where rows start on pages
# 2 and up, where the content starts when a page has no table, and where
# the page body ends (the footer is the same on every page, so that limit
# holds for page 1 as well).
sub measure_continuation_page ($template, $column_widths, $measure_text) {
	my $parts = $template->build_page(
		page_number   => 2,
		page_count    => 2,
		page_height   => PAGE_HEIGHT,
		with_table    => 1,
		rows          => [],
		with_closing  => 0,
		column_widths => $column_widths,
	);
	my ($ui) = lay_out($parts, PAGE_HEIGHT, $measure_text);
	return {
		rows_top    => bottom_of($ui->bounding_box($parts->{header_cells}[0])),
		content_top => $ui->bounding_box($parts->{table})->{y},
		body_bottom => bottom_of($ui->bounding_box($parts->{body})),
	};
}

# ---- Paginate: split the rows by their measured heights ----

# Rows fill a page until the next one would cross the body's bottom edge;
# that row starts the next page, below a repeated table header. The
# closing block (totals and payment terms) follows the last row if it
# fits there, otherwise it gets a page of its own without a table.
# Returns one arrayref of item indices per page.
sub paginate ($table, $continuation) {
	my $limit = $continuation->{body_bottom};
	my @pages = ([]);
	my $y     = $table->{first_rows_top};

	for my $index (0 .. $table->{row_heights}->$#*) {
		my $height = $table->{row_heights}[$index];
		die "Row $index is $height points high and does not fit on any page\n"
			if $continuation->{rows_top} + $height > $limit;
		if ($y + $height > $limit) {
			push @pages, [];
			$y = $continuation->{rows_top};
		}
		push $pages[-1]->@*, $index;
		$y += $height;
	}

	die "The totals and payment terms do not fit on a page\n"
		if $continuation->{content_top} + $table->{closing_height} > $limit;
	push @pages, [] if $y + $table->{closing_gap} + $table->{closing_height} > $limit;
	return \@pages;
}

# The pages must come out as measured: fail loudly if a row moved past
# the body's bottom edge or changed its height.
sub check_page ($ui, $parts, $table, $page_rows, $limit) {
	my $rows = $parts->{rows};
	for my $k (0 .. $#$rows) {
		my $box      = $ui->bounding_box($rows->[$k]);
		my $expected = $table->{row_heights}[ $page_rows->[$k] ];
		die "Row $page_rows->[$k] is $box->{height} points high, measured $expected\n"
			if abs($box->{height} - $expected) > 0.01;
		die "Row $page_rows->[$k] ends at $box->{y} + $box->{height}, below the page body ($limit)\n"
			if bottom_of($box) > $limit + 0.01;
	}
	return unless $parts->{closing};
	die "The closing block ends below the page body\n"
		if bottom_of($ui->bounding_box($parts->{closing})) > $limit + 0.01;
	return;
}

# ---- Main program ----

my ($output, $item_count) = @ARGV;
$output //= 'out.pdf';
$item_count //= 45;
die "item_count must be a positive integer\n" unless $item_count =~ /^[1-9][0-9]*$/;

my $invoice  = build_invoice($item_count);
my $template = Invoice::Template->new(invoice => $invoice);

my $pdf = PDF::Builder->new;
$pdf->info(Title => "Invoice $invoice->{number}", Author => $invoice->{seller}{name}, CreationDate => 'D:20261001120000Z');
my %fonts = (
	FONT_REGULAR() => $pdf->corefont('Helvetica'),
	FONT_BOLD()    => $pdf->corefont('Helvetica-Bold'),
);
my %drawings     = (DRAWING_LOGO() => \&draw_logo);
my $measure_text = make_measure_text(\%fonts);

my $column_widths = measure_columns($template, $item_count, $measure_text);
my $table        = measure_rows($template, $item_count, $column_widths, $measure_text);
my $continuation = measure_continuation_page($template, $table->{column_widths}, $measure_text);
my $pages        = paginate($table, $continuation);

# ---- Lay out and draw every page ----

my $page_count = @$pages;
for my $page_index (0 .. $page_count - 1) {
	my $page_rows = $pages->[$page_index];
	my $is_last   = $page_index == $page_count - 1;
	my $parts     = $template->build_page(
		page_number   => $page_index + 1,
		page_count    => $page_count,
		page_height   => PAGE_HEIGHT,
		with_table    => scalar @$page_rows,
		rows          => $page_rows,
		with_closing  => $is_last,
		column_widths => $table->{column_widths},
	);
	my ($ui, $commands) = lay_out($parts, PAGE_HEIGHT, $measure_text);
	check_page($ui, $parts, $table, $page_rows, $continuation->{body_bottom});

	my $page = $pdf->page;
	$page->mediabox(0, 0, PAGE_WIDTH, PAGE_HEIGHT);
	render_to_pdf_page($commands, $page, \%fonts, \%drawings);

	my $rows_text = @$page_rows ? sprintf('items %d-%d', $page_rows->[0] + 1, $page_rows->[-1] + 1) : 'no items';
	printf "page %d: %s%s\n", $page_index + 1, $rows_text, $is_last ? ', totals' : '';
}

$pdf->saveas($output);
printf "wrote %s: %d pages, %d items, total %s %s\n",
	$output, $page_count, $item_count, $invoice->{currency}, format_money($invoice->{total});
