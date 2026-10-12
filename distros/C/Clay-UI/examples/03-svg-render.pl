#!/usr/bin/env perl

# 03-svg-render.pl - Draw Clay's render commands as an SVG image.
#
# Contains a small renderer, render_to_svg(\@commands, $width, $height),
# that turns RECTANGLE, BORDER and TEXT commands into SVG elements; other
# command types are written as comments. The demo lays out a header and
# three cards and writes the SVG to the path given as argument, or to
# stdout without one. Example 11 extends the renderer to images, custom
# elements, clipping and overlays.
#
# Shows:
#   - a renderer: one drawing routine per render command type
#   - borders with a different width per edge
#   - placing text inside the box Clay computed for it
#   - centring children on both axes
#
# Features: Clay_Initialize, Clay_MinMemorySize, Clay_SetMeasureTextFunction, Clay_BeginLayout, Clay_EndLayout, Clay__OpenElementWithId, Clay_GetElementId, Clay_GetElementIdWithIndex, Clay__ConfigureOpenElement, Clay__OpenTextElement, Clay__CloseElement, commandType, boundingBox, renderData, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_TEXT, backgroundColor, cornerRadius, border, stringContents, fontSize, textColor, childAlignment, CLAY_ALIGN_X_LEFT, CLAY_ALIGN_X_CENTER, CLAY_ALIGN_Y_CENTER, CLAY_TOP_TO_BOTTOM, sizing_grow, sizing_fixed, padding_all, border_all, corner_radius_all
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/03-svg-render.pl [out.svg]

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# ---------------------------------------------------------------------------
# SVG renderer
# ---------------------------------------------------------------------------

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
# Demo layout
# ---------------------------------------------------------------------------

my ($W, $H) = (480, 280);

my $ctx = Clay_Initialize(
	Clay_MinMemorySize(),
	{ width => $W, height => $H },
	sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);

# Monospace fonts (DejaVu Sans Mono, Courier, ...) advance 0.6 of the
# font size per character; render_text draws with font-family monospace.
Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
	my $fs = $config->{fontSize} || 16;
	return { width => length($text) * $fs * 0.6, height => $fs };
});

Clay_BeginLayout();

Clay__OpenElementWithId( Clay_GetElementId("root") );
Clay__ConfigureOpenElement({
	layout => {
		sizing          => { width => sizing_grow(), height => sizing_grow() },
		padding         => padding_all(16),
		childGap        => 12,
		layoutDirection => CLAY_TOP_TO_BOTTOM,
	},
	backgroundColor => [245, 246, 250, 255],
});

	Clay__OpenElementWithId( Clay_GetElementId("header") );
	Clay__ConfigureOpenElement({
		layout          => {
			sizing         => { width => sizing_grow(), height => sizing_fixed(48) },
			padding        => padding_all(12),
			childAlignment => { x => CLAY_ALIGN_X_LEFT, y => CLAY_ALIGN_Y_CENTER },
		},
		backgroundColor => [50, 100, 200, 255],
		cornerRadius    => corner_radius_all(6),
	});
		Clay__OpenTextElement(
			"Clay -> SVG demo",
			{ fontSize => 20, textColor => [255, 255, 255, 255] },
		);
	Clay__CloseElement();

	Clay__OpenElementWithId( Clay_GetElementId("body") );
	Clay__ConfigureOpenElement({
		layout => {
			sizing   => { width => sizing_grow(), height => sizing_grow() },
			padding  => padding_all(12),
			childGap => 12,
		},
		backgroundColor => [255, 255, 255, 255],
		border          => { color => [200, 200, 210, 255], width => border_all(2) },
		cornerRadius    => corner_radius_all(6),
	});

		for my $i (0 .. 2) {
			Clay__OpenElementWithId( Clay_GetElementIdWithIndex("card", $i) );
			Clay__ConfigureOpenElement({
				layout => {
					sizing         => { width => sizing_grow(), height => sizing_grow() },
					padding        => padding_all(8),
					childAlignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
				},
				backgroundColor => [225 - $i * 40, 138, 50 + $i * 30, 255],
				cornerRadius    => corner_radius_all(4),
			});
				Clay__OpenTextElement(
					"card $i",
					{ fontSize => 16, textColor => [255, 255, 255, 255] },
				);
			Clay__CloseElement();
		}

	Clay__CloseElement();

Clay__CloseElement();

my $commands = Clay_EndLayout(0);
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
