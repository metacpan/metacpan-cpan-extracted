#!/usr/bin/env perl

# 11-xs-images-custom.pl - Images, custom elements and clipping, drawn as SVG.
#
# Clay never sees pixels: an image element carries an integer (imageData)
# and a custom element another one (customData), and the renderer looks
# them up in its own tables. This script builds a page with images kept
# at their aspect ratio, custom-drawn charts and stars, rounded corners,
# separator borders, an overlay colour and a clipped strip, renders every
# command type to SVG, and first shows check_struct rejecting bad
# declarations. Without an argument the SVG goes to stdout and the
# check_struct report to STDERR; with a path the SVG is written there and
# the report goes to stdout.
#
# Shows:
#   - images: imageData as a key into a Perl table of images
#   - aspect ratio, as a plain number and as a hash
#   - custom elements: customData as a key into a table of draw callbacks
#   - userData as a key into the renderer's notes (SVG tooltips)
#   - a different corner radius per corner
#   - borders with separators between children
#   - an overlay colour washing out a whole card
#   - clipping, drawn through SCISSOR_START / SCISSOR_END
#   - validating a declaration without a context, and the error object
#
# Features: image, imageData, custom, customData, aspectRatio, userData, cornerRadius, border, betweenChildren, border_outside, overlayColor, clip, childOffset, check_struct, Clay::XS::StructError, path, expected, got, hint, unknown_keys, known_keys, message, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_TEXT, CLAY_RENDER_COMMAND_TYPE_IMAGE, CLAY_RENDER_COMMAND_TYPE_CUSTOM, CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/11-xs-images-custom.pl [out.svg]

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

my ($WIDTH, $HEIGHT) = (520, 400);
my $output_path = shift @ARGV;

# ---------------------------------------------------------------------------
# The renderer's own tables: Clay only passes the integer keys through
# ---------------------------------------------------------------------------

# Images, keyed by the imageData integer. Each is an SVG fragment drawn in
# a 1 x 1 unit square, so it stretches to whatever box Clay computes.
my %IMAGES = (
	1 => {
		name => 'mountain',
		unit_svg => '<rect width="1" height="1" fill="#9cd3f0"/>'
			. '<polygon points="0,1 0.35,0.35 0.55,0.65 0.72,0.45 1,1" fill="#4f7d5a"/>'
			. '<circle cx="0.82" cy="0.22" r="0.08" fill="#ffd34d"/>',
	},
	2 => {
		name => 'avatar',
		unit_svg => '<rect width="1" height="1" fill="#b48ad6"/>'
			. '<circle cx="0.5" cy="0.4" r="0.2" fill="#fff"/>'
			. '<ellipse cx="0.5" cy="1" rx="0.36" ry="0.32" fill="#fff"/>',
	},
	3 => {
		name => 'tile',
		unit_svg => '<rect width="1" height="1" fill="#f2c14e"/>'
			. '<rect width="0.5" height="0.5" fill="#f78154"/>'
			. '<rect x="0.5" y="0.5" width="0.5" height="0.5" fill="#f78154"/>',
	},
);

# Custom elements, keyed by the customData integer. Each callback gets the
# bounding box and the command's renderData and returns SVG.
my %CUSTOM_DRAWERS = (
	1 => \&draw_pie_chart,
	2 => \&draw_star,
);

# Notes for elements, keyed by the userData integer; drawn as SVG
# <title> tooltips. 0 is what Clay reports when no userData was set.
my %NOTES = (
	101 => 'Photo, kept at 4:3',
	102 => 'Avatar, kept square',
	103 => 'Enabled card',
	104 => 'Disabled card: overlayColor washes it out',
);

# ---------------------------------------------------------------------------
# Checking declarations before using them
# ---------------------------------------------------------------------------

# check_struct needs no context. It applies the rules Clay::XS uses when a
# declaration crosses into Clay, plus stricter ones (unknown keys are an
# error), and dies with a Clay::XS::StructError for the first problem.
sub check_struct_report () {
	my @bad_declarations = (
		[ 'a number where a struct belongs', { layout => { padding => 8 } } ],
		[ 'a misspelt key',                  { backgroundColour => [255, 0, 0, 255] } ],
		[ 'a negative image key',            { image => { imageData => -1 } } ],
	);
	my @report;
	for my $case (@bad_declarations) {
		my ($what, $declaration) = @$case;
		my $error = do {
			local $@;
			eval { check_struct('Clay_ElementDeclaration', $declaration); 1 } ? undef : $@;
		};
		die "check_struct accepted $what\n" unless $error;
		die $error unless ref $error && $error->isa('Clay::XS::StructError');

		push @report, "check_struct with $what:",
			'    message:  ' . $error->message,
			'    path:     ' . join(' -> ', @{ $error->path }),
			'    expected: ' . $error->expected,
			'    got:      ' . $error->got;
		push @report, '    hint:     ' . $error->hint if defined $error->hint;
		push @report, '    unknown:  ' . join(', ', @{ $error->unknown_keys }) if $error->unknown_keys;
		push @report, '    known:    ' . join(', ', @{ $error->known_keys })   if $error->known_keys;
	}
	return @report;
}

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

# SVG 1.1 has no rgba(): the colour goes into fill (or stroke) as rgb()
# and the alpha into fill-opacity (or stroke-opacity).
sub paint_attributes ($property, $c) {
	my $attributes = sprintf '%s="rgb(%d,%d,%d)"', $property, $c->{r}, $c->{g}, $c->{b};
	return $attributes if $c->{a} >= 255;
	return sprintf '%s %s-opacity="%.3f"', $attributes, $property, $c->{a} / 255;
}

sub fill_attributes ($c)   { paint_attributes('fill', $c) }
sub stroke_attributes ($c) { paint_attributes('stroke', $c) }

sub svg_title ($cmd) {
	my $note = $NOTES{ $cmd->{userData} };
	return defined $note ? '<title>' . xml_escape($note) . '</title>' : '';
}

# A rectangle with its own radius per corner, as an SVG path. A radius
# never exceeds half the shorter side, so opposite corners cannot overlap.
sub rounded_rect_path ($box, $radii) {
	my ($x, $y, $w, $h) = @$box{qw(x y width height)};
	my $cap = ($w < $h ? $w : $h) / 2;
	my ($tl, $tr, $br, $bl) = map { my $r = $radii->{$_} // 0; $r > $cap ? $cap : $r }
		qw(topLeft topRight bottomRight bottomLeft);
	return sprintf 'M%g,%g H%g A%g,%g 0 0 1 %g,%g V%g A%g,%g 0 0 1 %g,%g H%g A%g,%g 0 0 1 %g,%g V%g A%g,%g 0 0 1 %g,%g Z',
		$x + $tl, $y,
		$x + $w - $tr, $tr, $tr, $x + $w, $y + $tr,
		$y + $h - $br, $br, $br, $x + $w - $br, $y + $h,
		$x + $bl, $bl, $bl, $x, $y + $h - $bl,
		$y + $tl, $tl, $tl, $x + $tl, $y;
}

sub render_rectangle ($cmd, $defs) {
	my $data = $cmd->{renderData};
	return sprintf qq{  <path d="%s" %s>%s</path>\n},
		rounded_rect_path($cmd->{boundingBox}, $data->{cornerRadius}), fill_attributes($data->{backgroundColor}), svg_title($cmd);
}

# A border lies inside the element's box. With the same width on every
# edge it is the rounded outline, stroked half a width inside the box;
# otherwise one filled strip per edge, inside the box along that edge
# (ignoring corner radii), keeps this renderer short. The separators between children (betweenChildren)
# are not part of this command: Clay emits them as RECTANGLEs.
sub render_border ($cmd, $defs) {
	my ($x, $y, $w, $h) = @{ $cmd->{boundingBox} }{qw(x y width height)};
	my $width = $cmd->{renderData}{width};
	my $color = $cmd->{renderData}{color};
	my %edge_widths = map { $_ => 1 } @$width{qw(left right top bottom)};
	if (keys %edge_widths == 1) {
		my $inset  = $width->{top} / 2;
		my $inner  = { x => $x + $inset, y => $y + $inset, width => $w - 2 * $inset, height => $h - 2 * $inset };
		my %radius = map { $_ => ($cmd->{renderData}{cornerRadius}{$_} // 0) - $inset } qw(topLeft topRight bottomRight bottomLeft);
		return sprintf qq{  <path d="%s" fill="none" %s stroke-width="%g"/>\n},
			rounded_rect_path($inner, { map { $_ => $radius{$_} > 0 ? $radius{$_} : 0 } keys %radius }),
			stroke_attributes($color), $width->{top};
	}
	my ($top, $bottom, $left, $right) = @$width{qw(top bottom left right)};
	my @strips = (    # x, y, width, height of each edge's strip
		[ $x,               $y,                $w,     $top ],
		[ $x,               $y + $h - $bottom, $w,     $bottom ],
		[ $x,               $y,                $left,  $h ],
		[ $x + $w - $right, $y,                $right, $h ],
	);
	return join '', map {
		sprintf qq{  <rect x="%g" y="%g" width="%g" height="%g" %s/>\n}, @$_, fill_attributes($color)
	} grep { $_->[2] > 0 && $_->[3] > 0 } @strips;
}

sub render_text ($cmd, $defs) {
	my $box  = $cmd->{boundingBox};
	my $data = $cmd->{renderData};
	return sprintf qq{  <text x="%g" y="%g" font-size="%g" font-family="sans-serif" %s xml:space="preserve">%s</text>\n},
		$box->{x}, $box->{y} + $box->{height} * 0.85, $data->{fontSize}, fill_attributes($data->{textColor}),
		xml_escape( $data->{stringContents} );
}

# The image is a <pattern> scaled to the element's box, used as the fill
# of the rounded outline. renderData.backgroundColor would be a tint; this
# renderer ignores it (and Clay would also draw it as a RECTANGLE on top).
sub render_image ($cmd, $defs) {
	my $key   = $cmd->{renderData}{imageData};
	my $image = $IMAGES{$key} or die "render_image: no image with key $key\n";
	$defs->{"image-$key"} //= sprintf
		qq{    <pattern id="image-%d" patternUnits="objectBoundingBox" patternContentUnits="objectBoundingBox" width="1" height="1">%s</pattern>\n},
		$key, $image->{unit_svg};
	return sprintf qq{  <path d="%s" fill="url(#image-%d)">%s</path>\n},
		rounded_rect_path($cmd->{boundingBox}, $cmd->{renderData}{cornerRadius}), $key, svg_title($cmd);
}

sub render_custom ($cmd, $defs) {
	my $key    = $cmd->{renderData}{customData};
	my $drawer = $CUSTOM_DRAWERS{$key} or die "render_custom: no drawer with key $key\n";
	return $drawer->($cmd->{boundingBox}, $cmd->{renderData});
}

# SCISSOR_START opens a group clipped to its box; the matching
# SCISSOR_END closes it. Overlays work the same way, so both share the
# stack of open groups.
sub render_scissor_start ($cmd, $defs) {
	my $clip_id = 'clip-' . (keys(%$defs) + 1);
	$defs->{$clip_id} = sprintf qq{    <clipPath id="%s"><rect x="%g" y="%g" width="%g" height="%g"/></clipPath>\n},
		$clip_id, @{ $cmd->{boundingBox} }{qw(x y width height)};
	return qq{  <g clip-path="url(#$clip_id)">\n};
}

# An overlay mixes its colour over everything drawn until OVERLAY_COLOR_END,
# by the colour's alpha. The SVG filter paints the colour "atop" the group:
# the same mix, and only where the group drew something.
sub render_overlay_start ($cmd, $defs) {
	my $filter_id = 'overlay-' . (keys(%$defs) + 1);
	my $color     = $cmd->{renderData}{color};
	$defs->{$filter_id} = sprintf
		qq{    <filter id="%s"><feFlood flood-color="rgb(%d,%d,%d)" flood-opacity="%.3f"/>}
		. qq{<feComposite in2="SourceGraphic" operator="atop"/></filter>\n},
		$filter_id, @$color{qw(r g b)}, $color->{a} / 255;
	return qq{  <g filter="url(#$filter_id)">\n};
}

sub render_group_end ($cmd, $defs) {
	return "  </g>\n";
}

my %RENDERER_FOR = (
	CLAY_RENDER_COMMAND_TYPE_RECTANGLE()           => \&render_rectangle,
	CLAY_RENDER_COMMAND_TYPE_BORDER()              => \&render_border,
	CLAY_RENDER_COMMAND_TYPE_TEXT()                => \&render_text,
	CLAY_RENDER_COMMAND_TYPE_IMAGE()               => \&render_image,
	CLAY_RENDER_COMMAND_TYPE_CUSTOM()              => \&render_custom,
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_START()       => \&render_scissor_start,
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_END()         => \&render_group_end,
	CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START() => \&render_overlay_start,
	CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END()   => \&render_group_end,
);

# Clay returns the commands in drawing order (z order included), so they
# are drawn as they come; sorting them would break the start/end pairs.
sub render_to_svg ($commands, $width, $height) {
	my %defs;
	my $body = '';
	for my $cmd (@$commands) {
		my $renderer = $RENDERER_FOR{ $cmd->{commandType} }
			or die "render_to_svg: unknown commandType $cmd->{commandType}\n";
		$body .= $renderer->($cmd, \%defs);
	}
	my $defs = join '', map { $defs{$_} } sort keys %defs;
	return sprintf(qq{<svg xmlns="http://www.w3.org/2000/svg" width="%g" height="%g" viewBox="0 0 %g %g">\n},
		$width, $height, $width, $height)
		. "  <defs>\n$defs  </defs>\n"
		. $body
		. "</svg>\n";
}

# ---------------------------------------------------------------------------
# Custom draw callbacks
# ---------------------------------------------------------------------------

my $PI = 4 * atan2(1, 1);

# A pie chart, as large as fits into the box.
sub draw_pie_chart ($box, $render_data) {
	my ($cx, $cy) = ($box->{x} + $box->{width} / 2, $box->{y} + $box->{height} / 2);
	my $radius    = ($box->{width} < $box->{height} ? $box->{width} : $box->{height}) / 2 - 8;
	my @slices    = ([0.45, '#4e79a7'], [0.30, '#f28e2b'], [0.25, '#59a14f']);
	my $svg       = '';
	my $start     = 0;
	for my $slice (@slices) {
		my ($share, $color) = @$slice;
		my $end = $start + $share;
		my @from = ($cx + $radius * sin(2 * $PI * $start), $cy - $radius * cos(2 * $PI * $start));
		my @to   = ($cx + $radius * sin(2 * $PI * $end),   $cy - $radius * cos(2 * $PI * $end));
		$svg .= sprintf qq{  <path d="M%g,%g L%.2f,%.2f A%g,%g 0 %d 1 %.2f,%.2f Z" fill="%s"/>\n},
			$cx, $cy, @from, $radius, $radius, ($share > 0.5 ? 1 : 0), @to, $color;
		$start = $end;
	}
	return $svg;
}

# A five-pointed star centred in the box.
sub draw_star ($box, $render_data) {
	my ($cx, $cy) = ($box->{x} + $box->{width} / 2, $box->{y} + $box->{height} / 2);
	my $outer     = ($box->{width} < $box->{height} ? $box->{width} : $box->{height}) / 2;
	my @points;
	for my $corner (0 .. 9) {
		my $radius = $corner % 2 ? $outer * 0.45 : $outer;
		my $angle  = $PI * $corner / 5;
		push @points, sprintf '%.2f,%.2f', $cx + $radius * sin($angle), $cy - $radius * cos($angle);
	}
	return sprintf qq{  <polygon points="%s" fill="#f0b41e"/>\n}, join(' ', @points);
}

# ---------------------------------------------------------------------------
# The layout
# ---------------------------------------------------------------------------

sub text ($string, $size = 14, $color = [40, 40, 50, 255]) {
	Clay__OpenTextElement($string, { fontSize => $size, textColor => $color });
}

sub declare_gallery () {
	Clay__OpenElementWithId( Clay_GetElementId('gallery') );
	Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_grow() }, childGap => 12 } });

		# Only the width is given; aspectRatio (width / height) sets the
		# height. The plain-number form:
		Clay__OpenElementWithId( Clay_GetElementId('photo') );
		Clay__ConfigureOpenElement({
			layout       => { sizing => { width => sizing_fixed(160) } },
			aspectRatio  => 4 / 3,
			image        => { imageData => 1 },
			cornerRadius => { topLeft => 24, topRight => 0, bottomRight => 24, bottomLeft => 0 },
			userData     => 101,
		});
		Clay__CloseElement();

		# The hash form, with the C struct's field name.
		Clay__OpenElementWithId( Clay_GetElementId('avatar') );
		Clay__ConfigureOpenElement({
			layout       => { sizing => { width => sizing_fixed(90) } },
			aspectRatio  => { aspectRatio => 1 },
			image        => { imageData => 2 },
			cornerRadius => corner_radius_all(45),
			userData     => 102,
		});
		Clay__CloseElement();

		# A custom element: Clay lays it out like any box and hands the
		# drawing to the renderer through a CUSTOM render command. Clay
		# also emits a RECTANGLE, drawn after the CUSTOM command, for a
		# backgroundColor on the same element, so the card behind the
		# chart is a parent element of its own.
		Clay__OpenElementWithId( Clay_GetElementId('chart-card') );
		Clay__ConfigureOpenElement({
			layout          => { sizing => { width => sizing_grow(), height => sizing_fixed(120) } },
			backgroundColor => [255, 255, 255, 255],
			cornerRadius    => corner_radius_all(8),
		});
			Clay__OpenElementWithId( Clay_GetElementId('chart') );
			Clay__ConfigureOpenElement({
				layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
				custom => { customData => 1 },
			});
			Clay__CloseElement();
		Clay__CloseElement();

	Clay__CloseElement();
}

sub declare_toolbar () {
	Clay__OpenElementWithId( Clay_GetElementId('toolbar') );
	Clay__ConfigureOpenElement({
		layout => {
			padding        => { left => 12, right => 12, top => 8, bottom => 8 },
			childGap       => 25,
			childAlignment => { y => CLAY_ALIGN_Y_CENTER },
		},
		backgroundColor => [255, 255, 255, 255],
		# betweenChildren draws a separator in the middle of every childGap.
		border => {
			color => [150, 155, 170, 255],
			width => { left => 1, right => 1, top => 1, bottom => 1, betweenChildren => 1 },
		},
	});
		text($_) for qw(Cut Copy Paste Delete);
	Clay__CloseElement();
}

sub declare_card ($index, $disabled) {
	Clay__OpenElementWithId( Clay_GetElementIdWithIndex('card', $index) );
	Clay__ConfigureOpenElement({
		layout => {
			sizing         => { width => sizing_grow() },
			padding        => padding_all(12),
			childGap       => 12,
			childAlignment => { y => CLAY_ALIGN_Y_CENTER },
		},
		backgroundColor => [255, 255, 255, 255],
		cornerRadius    => corner_radius_all(10),
		# border_outside sets the four edges only; border_all would also
		# set betweenChildren and draw a bar between the star and the text.
		border          => { color => [70, 110, 200, 255], width => border_outside(2) },
		# The overlay is mixed over the card and everything in it, by its
		# alpha: here 55% white.
		overlayColor => $disabled ? [255, 255, 255, 140] : [0, 0, 0, 0],
		userData     => $disabled ? 104 : 103,
	});
		Clay__OpenElement();
		Clay__ConfigureOpenElement({
			layout => { sizing => { width => sizing_fixed(36), height => sizing_fixed(36) } },
			custom => { customData => 2 },
		});
		Clay__CloseElement();
		text($disabled ? 'Disabled card' : 'Enabled card', 16);
	Clay__CloseElement();
}

sub declare_clipped_strip () {
	Clay__OpenElementWithId( Clay_GetElementId('strip') );
	Clay__ConfigureOpenElement({
		layout => {
			sizing   => { width => sizing_grow(), height => sizing_fixed(64) },
			padding  => padding_all(8),
			childGap => 8,
		},
		backgroundColor => [60, 64, 80, 255],
		cornerRadius    => corner_radius_all(6),
		# Content wider than the strip is clipped to it. A fixed
		# childOffset shifts the content left, so both ends are cut off;
		# a scrolling list would pass Clay_GetScrollOffset() here.
		clip => { horizontal => 1, childOffset => { x => -30, y => 0 } },
	});
		for my $index (0 .. 9) {
			Clay__OpenElementWithId( Clay_GetElementIdWithIndex('thumb', $index) );
			# aspectRatio derives the width from a FIXED height (a GROW
			# height is only known after widths are final).
			Clay__ConfigureOpenElement({
				layout       => { sizing => { height => sizing_fixed(48) } },
				aspectRatio  => 1,
				image        => { imageData => 3 },
				cornerRadius => corner_radius_all(4),
			});
			Clay__CloseElement();
		}
	Clay__CloseElement();
}

sub declare_page () {
	Clay__OpenElementWithId( Clay_GetElementId('page') );
	Clay__ConfigureOpenElement({
		layout => {
			sizing          => { width => sizing_grow(), height => sizing_grow() },
			layoutDirection => CLAY_TOP_TO_BOTTOM,
			padding         => padding_all(16),
			childGap        => 14,
		},
		backgroundColor => [236, 239, 245, 255],
	});
		text('Images, custom elements and clipping', 18);
		declare_gallery();
		declare_toolbar();
		Clay__OpenElementWithId( Clay_GetElementId('cards') );
		Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_grow() }, childGap => 12 } });
			declare_card(0, 0);
			declare_card(1, 1);
		Clay__CloseElement();
		declare_clipped_strip();
	Clay__CloseElement();
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

my @report = check_struct_report();

my $ctx = Clay_Initialize(
	Clay_MinMemorySize(),
	{ width => $WIDTH, height => $HEIGHT },
	sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);
Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
	my $font_size = $config->{fontSize} || 16;
	return { width => length($text) * $font_size * 0.55, height => $font_size };
});

Clay_BeginLayout();
declare_page();
my $svg = render_to_svg(Clay_EndLayout(0), $WIDTH, $HEIGHT);

if (!defined $output_path) {
	print $svg;
	print STDERR "$_\n" for @report;
	exit 0;
}

open my $out, '>', $output_path or die "Cannot write $output_path: $!\n";
print {$out} $svg;
close $out or die "Cannot write $output_path: $!\n";
say for @report;
say "Wrote $output_path";
