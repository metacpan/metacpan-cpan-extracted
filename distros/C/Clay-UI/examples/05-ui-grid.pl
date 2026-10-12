#!/usr/bin/env perl

# 05-ui-grid.pl - An auto-sized data table with Clay::UI::Grid, as SVG.
#
# Each column is as wide as its widest cell and each row as tall as its
# tallest cell, in one layout pass (Clay's sizing groups, added by a patch
# to clay.h). The header is a grid of its own that shares its columns with
# the body grid, as a table with a scrolling body would; the body rows are
# sorted by region after they were added, and a note spans the full width.
# The SVG goes to the path given as argument, or to stdout without one.
#
# Shows:
#   - columns and rows that size themselves to their content
#   - styled cells (background, border, padding) that are the visible boxes
#   - two grids that share column widths
#   - sorting rows without rebuilding them
#   - a row with one cell as wide as the whole grid
#
# Features: Clay::UI, Clay::UI::Grid, Clay::UI::Grid::Cell, Clay::UI::Box, Clay::UI::Text, append_row, append_spanning_row, reorder_rows, share_columns_with, cell_gap, row_gap, sizing_percent, sizing_grow, padding_all, border_color, border_width, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_TEXT
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/05-ui-grid.pl [out.svg]

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Grid::Cell;
use Clay::UI::Text;
use Clay::UI::Grid;

# Clay::UI ships roles, not classes: each widget class is one line that
# composes the role it needs (see Clay::Manual, GETTING STARTED).
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}
class My::Grid :strict(params) :does(Clay::UI::Grid) {}

# ---------------------------------------------------------------------------
# SVG renderer
# ---------------------------------------------------------------------------
# Same renderer as examples/03-svg-render.pl; see there for explanations.

sub xml_escape ($text) {
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/"/&quot;/g;
	return $text;
}

# SVG 1.1 has no rgba() colours: the alpha channel goes into its own
# fill-opacity (or stroke-opacity) attribute.
sub svg_paint ($attribute, $c) {
	return sprintf '%s="rgb(%d,%d,%d)" %s-opacity="%.3f"',
		$attribute, $c->{r}, $c->{g}, $c->{b}, $attribute, $c->{a} / 255;
}

# Clay stores per-corner radii; SVG <rect> only supports a single rx/ry. When
# the four corners differ we approximate with rx = average, which is the
# pragmatic choice for a debug/preview renderer.
sub corner_radius ($cr) {
	return 0 unless $cr;
	my @r = ($cr->{topLeft}, $cr->{topRight}, $cr->{bottomLeft}, $cr->{bottomRight});
	my $sum = 0; $sum += $_ for @r;
	return $sum / 4;
}

sub render_rectangle ($cmd) {
	my $b  = $cmd->{boundingBox};
	my $d  = $cmd->{renderData};
	my $r  = corner_radius($d->{cornerRadius});
	my $rx = $r ? sprintf(' rx="%g" ry="%g"', $r, $r) : '';
	return sprintf
		qq{  <rect x="%g" y="%g" width="%g" height="%g"%s %s/>\n},
		$b->{x}, $b->{y}, $b->{width}, $b->{height}, $rx,
		svg_paint('fill', $d->{backgroundColor});
}

# Clay borders lie inside the bounding box: a left border 2 wide covers
# the box's two leftmost columns. A border of one width all round with
# rounded corners is one stroked <rect>; SVG centres a stroke on its
# outline, so the outline is inset by half the width. Any other border
# becomes one filled <rect> per edge (corner radii ignored for clarity);
# the left and right edges fit between the top and bottom ones, so no
# pixel is painted twice (that would darken translucent borders).
sub render_border ($cmd) {
	my $b = $cmd->{boundingBox};
	my $d = $cmd->{renderData};
	my $w = $d->{width};
	my ($x, $y, $bw, $bh) = ($b->{x}, $b->{y}, $b->{width}, $b->{height});
	my $r = corner_radius($d->{cornerRadius});

	my $is_uniform = !grep { $_ != $w->{top} } @$w{qw(right bottom left)};
	if ($r > 0 && $w->{top} > 0 && $is_uniform) {
		my $half = $w->{top} / 2;
		my $rx   = $r > $half ? $r - $half : 0;
		return sprintf
			qq{  <rect x="%g" y="%g" width="%g" height="%g" rx="%g" ry="%g" fill="none" %s stroke-width="%g"/>\n},
			$x + $half, $y + $half, $bw - $w->{top}, $bh - $w->{top}, $rx, $rx,
			svg_paint('stroke', $d->{color}), $w->{top};
	}

	my $side_height = $bh - $w->{top} - $w->{bottom};
	my @edges = (
		[ $x,                     $y,                      $bw,         $w->{top}    ],
		[ $x,                     $y + $bh - $w->{bottom}, $bw,         $w->{bottom} ],
		[ $x,                     $y + $w->{top},          $w->{left},  $side_height ],
		[ $x + $bw - $w->{right}, $y + $w->{top},          $w->{right}, $side_height ],
	);
	my $fill = svg_paint('fill', $d->{color});
	return join '', map {
		sprintf qq{  <rect x="%g" y="%g" width="%g" height="%g" %s/>\n}, @$_, $fill
	} grep { $_->[2] > 0 && $_->[3] > 0 } @edges;
}

# Clay reports the text bounding box already laid out for the configured
# fontSize. SVG's <text> y is the baseline; a quarter of the font size
# above the bottom of the box leaves room for descenders, close enough for
# a preview without real font metrics. The font is monospace to match the
# text measuring function (0.6 of the font size per character), so
# text fits the box Clay made for it.
sub render_text ($cmd) {
	my $b = $cmd->{boundingBox};
	my $d = $cmd->{renderData};
	return sprintf
		qq{  <text x="%g" y="%g" font-size="%g" font-family="monospace" %s xml:space="preserve">%s</text>\n},
		$b->{x}, $b->{y} + $b->{height} - $d->{fontSize} / 4, $d->{fontSize},
		svg_paint('fill', $d->{textColor}),
		xml_escape($d->{stringContents});
}

sub render_to_svg ($commands, $width, $height) {
	my $svg = sprintf
		qq{<svg xmlns="http://www.w3.org/2000/svg" width="%g" height="%g" viewBox="0 0 %g %g">\n},
		$width, $height, $width, $height;

	# Draw in array order; Clay has already sorted the commands (see
	# Clay::Manual, Writing a renderer).
	for my $cmd (@$commands) {
		my $type = $cmd->{commandType};
		$svg .=
			$type == CLAY_RENDER_COMMAND_TYPE_RECTANGLE ? render_rectangle($cmd) :
			$type == CLAY_RENDER_COMMAND_TYPE_BORDER    ? render_border($cmd)    :
			$type == CLAY_RENDER_COMMAND_TYPE_TEXT      ? render_text($cmd)      :
			sprintf(qq{  <!-- skipped commandType=%d -->\n}, $type);
	}

	$svg .= "</svg>\n";
	return $svg;
}

# ---------------------------------------------------------------------------
# Layout: a header grid and a body grid with deliberately uneven column
# widths to make the auto-fit obvious in the rendered SVG. Each cell is a
# Clay::UI::Grid::Cell carrying the styling: the grid uses it as the cell
# (it gets the column width and row height), and its content is a plain
# Text leaf, so what you see in the SVG IS the equalized box.
# ---------------------------------------------------------------------------

my $HEADER_BG = [55,  90, 140, 255];
my $CELL_BG   = [40,  46,  56, 255];
my $ALT_BG    = [50,  56,  68, 255];
my $BORDER    = [90, 100, 120, 255];
my $WHITE     = [240, 240, 245, 255];

sub label ($text, $font_size = 16) {
	return My::Text->new(
		text       => $text,
		font_size  => $font_size,
		text_color => $WHITE,
	);
}

sub header_cell ($text) {
	my $cell = Clay::UI::Grid::Cell->new(
		layout           => { padding => { left => 12, right => 12, top => 8, bottom => 8 } },
		background_color => $HEADER_BG,
		border_color     => $BORDER,
		border_width     => 1,
	);
	$cell->add_child(label($text, 18));
	return $cell;
}

sub body_cell ($text, $r) {
	my $cell = Clay::UI::Grid::Cell->new(
		layout           => { padding => { left => 12, right => 12, top => 8, bottom => 8 } },
		background_color => ($r % 2 ? $ALT_BG : $CELL_BG),
		border_color     => $BORDER,
		border_width     => 1,
	);
	$cell->add_child(label($text));
	return $cell;
}

# A spanning cell: a Grid::Cell is used as it is, so it needs its own
# sizing_percent(1) width to fill the row without widening the grid.
sub note_cell ($text) {
	my $cell = Clay::UI::Grid::Cell->new(
		layout           => {
			sizing  => { width => sizing_percent(1) },
			padding => { left => 12, right => 12, top => 6, bottom => 6 },
		},
		background_color => $HEADER_BG,
	);
	$cell->add_child(label($text, 14));
	return $cell;
}

my ($W, $H) = (820, 280);

my @header = ( 'Region', 'Q1', 'Q2', 'Q3', 'Q4 forecast' );
my @data = (
	[ 'North America',    '$1.2M',  '$1.5M',  '$1.8M',  '$2.1M'       ],
	[ 'Europe',           '$0.9M',  '$1.1M',  '$1.3M',  '$1.4M'       ],
	[ 'APAC',             '$0.4M',  '$0.7M',  '$1.0M',  '$1.3M'       ],
	[ 'Latin America',    '$0.2M',  '$0.3M',  '$0.5M',  '$0.7M'       ],
);

sub build_tree () {
	my $body = My::Grid->new(
		id       => 'Report',
		cell_gap => 0,
		row_gap  => 0,
	);
	for my $r (0 .. $#data) {
		$body->append_row([ map { body_cell($_, $r) } @{ $data[$r] } ]);
	}

	# Sort by region. reorder_rows moves the existing rows (row k becomes
	# the row that was at $order[k]), so the cells keep their state. The
	# zebra colours were given by the old position and move with them.
	my @order = sort { $data[$a][0] cmp $data[$b][0] } 0 .. $#data;
	$body->reorder_rows(\@order);

	$body->append_spanning_row(note_cell('Figures in US dollars; Q4 is a forecast.'));

	# The header grid shares the body's columns: column N of both grids
	# is as wide as the widest cell of column N in either. Both grids use
	# the same cell_gap, or the columns would drift apart.
	my $header = My::Grid->new(
		id                 => 'ReportHeader',
		cell_gap           => 0,
		share_columns_with => $body,
	);
	$header->append_row([ map { header_cell($_) } @header ]);

	my $page = My::Box->new(
		id => 'Page',
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => padding_all(24),
			child_gap        => 16,
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
		background_color => [22, 26, 32, 255],
	);
	my $table = My::Box->new(layout => { layout_direction => CLAY_TOP_TO_BOTTOM });
	$table->add_child($header, $body);
	$page->add_child(
		My::Text->new(
			text       => 'Quarterly numbers (auto-sized grid)',
			font_size  => 22,
			text_color => $WHITE,
		),
		$table,
	);
	return $page;
}

my $ui = Clay::UI->new(
	width         => $W,
	height        => $H,
	root          => build_tree(),
	# Monospace fonts (DejaVu Sans Mono, Courier, ...) advance 0.6 of the
	# font size per character; render_text draws with font-family monospace.
	measure_text  => sub ($text, $config, $userdata) {
		my $fs = $config->{fontSize} || 16;
		return { width => length($text) * $fs * 0.6, height => $fs };
	},
	error_handler => sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);

my $commands = $ui->render;
# ---- Write the SVG to the path given as argument, or to stdout ----

sub write_svg ($svg, $path) {
	if (!defined $path) {
		print $svg;
		return;
	}
	open my $fh, '>', $path or die "Cannot write $path: $!\n";
	print {$fh} $svg;
	close $fh or die "Cannot write $path: $!\n";
	print "Wrote $path\n";
}

write_svg(render_to_svg($commands, $W, $H), $ARGV[0]);
