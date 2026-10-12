#!/usr/bin/env perl

# 07-ui-flow.pl - Flow layout with Clay::UI, rendered to SVG.
#
# Any widget with a layout wraps its children onto new lines once it sets
# layout_direction => CLAY_LEFT_TO_RIGHT_WRAP. The page shows two wrap
# containers: a tag cloud whose lines keep their natural height and are
# centered line by line, and a fixed-height gallery whose lines share the
# leftover height, with separators between neighbours and between lines.
# The SVG goes to the path given as argument, or to stdout without one.
#
# Shows:
#   - children wrapping onto new lines when a row is full
#   - lines that keep their height (CLAY_LINE_SIZING_FIT) or share the
#     leftover height (CLAY_LINE_SIZING_GROW, the default)
#   - a gap between lines and centering within each line
#   - separators drawn between children and between lines
#
# Features: Clay::UI, Clay::UI::Box, Clay::UI::Text, CLAY_LEFT_TO_RIGHT_WRAP, line_gap, line_sizing, CLAY_LINE_SIZING_FIT, child_alignment, child_gap, border_width, between_children, corner_radius, sizing_grow, sizing_fixed, padding_all, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_TEXT
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/07-ui-flow.pl [out.svg]

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Text;

# Clay::UI ships roles, not classes: each widget class is one line that
# composes the role it needs (see Clay::Manual, GETTING STARTED).
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}

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
# Layout.
# ---------------------------------------------------------------------------

my $PAGE_BG  = [22,  26,  32, 255];
my $PANEL_BG = [34,  40,  50, 255];
my $TAG_BG   = [55,  90, 140, 255];
my $CARD_BG  = [60,  70,  86, 255];
my $LINE     = [110, 120, 140, 255];
my $WHITE    = [240, 240, 245, 255];

sub label ($text, $font_size = 16) {
	return My::Text->new(
		text       => $text,
		font_size  => $font_size,
		text_color => $WHITE,
	);
}

sub tag ($text) {
	my $tag = My::Box->new(
		layout           => { padding => { left => 10, right => 10, top => 4, bottom => 4 } },
		background_color => $TAG_BG,
		corner_radius    => 10,
	);
	$tag->add_child(label($text, 14));
	return $tag;
}

sub card ($title, $width) {
	my $card = My::Box->new(
		layout => {
			sizing           => { width => sizing_grow($width), height => sizing_grow() },
			padding          => padding_all(10),
			child_alignment  => { y => CLAY_ALIGN_Y_CENTER },
		},
		background_color => $CARD_BG,
	);
	$card->add_child(label($title));
	return $card;
}

sub build_tree () {
	my $tags = My::Box->new(
		layout => {
			sizing           => { width => sizing_grow() },
			padding          => padding_all(12),
			child_gap        => 8,
			line_gap         => 8,
			child_alignment  => { x => CLAY_ALIGN_X_CENTER },
			layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
			line_sizing      => CLAY_LINE_SIZING_FIT,
		},
		background_color => $PANEL_BG,
	);
	$tags->add_child(tag($_)) for qw(
		perl layout clay xs flexbox wrap lines gaps alignment
		sizing-groups grids scrolling transitions render-commands svg
	);

	my $gallery = My::Box->new(
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_fixed(260) },
			padding          => padding_all(12),
			child_gap        => 12,
			line_gap         => 12,
			layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
		},
		background_color => $PANEL_BG,
		border_color     => $LINE,
		border_width     => { between_children => 2 },
	);
	$gallery->add_child(card(@$_)) for (
		[ 'Mountains', 180 ], [ 'Harbour', 140 ], [ 'Old town', 160 ],
		[ 'Forest', 120 ], [ 'Lake at dawn', 220 ], [ 'Market', 130 ], [ 'Bridge', 150 ],
	);

	my $page = My::Box->new(
		id     => 'Page',
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => padding_all(24),
			child_gap        => 16,
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
		background_color => $PAGE_BG,
	);
	$page->add_child(
		label('Tags (lines fit their content, centered)', 20), $tags,
		label('Gallery (lines grow into the leftover height)', 20), $gallery,
	);
	return $page;
}

my ($W, $H) = (640, 600);

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
