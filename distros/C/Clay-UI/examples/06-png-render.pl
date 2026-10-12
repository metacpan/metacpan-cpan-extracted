#!/usr/bin/env perl

# 06-png-render.pl - Draw Clay's render commands as a PNG image with Imager.
#
# Builds a header and three cards with Clay::UI, measures text with a real
# font and rasterises the render commands with Imager. Each card wraps the
# same paragraph with a different text alignment. Rectangles and borders
# are antialiased and honour their corner radii. Writes the PNG to the
# path given as argument (out.png in the current directory by default).
#
# Shows:
#   - a raster renderer for RECTANGLE, BORDER and TEXT commands
#   - rounded corners drawn through an antialiased polygon mask
#   - measuring text with the same font the renderer draws with
#   - word wrapping and left, centred and right text alignment
#   - building the tree from Clay::UI widgets instead of Clay::XS calls
#
# Features: Clay::UI, Clay::UI::Box, Clay::UI::Text, render, measure_text, error_handler, text_alignment, CLAY_TEXT_ALIGN_LEFT, CLAY_TEXT_ALIGN_CENTER, CLAY_TEXT_ALIGN_RIGHT, corner_radius, border_color, border_width, cornerRadius, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_TEXT
#
# Requires: Imager with PNG support (Imager::File::PNG) and FreeType
#   (Imager::Font::FT2), and the DejaVu Sans Mono font (DejaVuSansMono.ttf).
#   Set CLAY_FONT_PATH to the directory that holds it if it is not in one
#   of the places probed below.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/06-png-render.pl [out.png]

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Imager;
use List::Util qw(min max);
use POSIX qw(floor ceil);
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
# Font resolution
# ---------------------------------------------------------------------------

sub locate_font ($file_name) {
	my @directories = (
		($ENV{CLAY_FONT_PATH} // ()),
		'/usr/share/fonts/truetype/dejavu',
		'/usr/share/fonts/TTF',
		'/usr/share/fonts/dejavu',
		'/usr/local/share/fonts',
		"$ENV{HOME}/.local/share/fonts",
	);
	for my $directory (@directories) {
		return "$directory/$file_name" if -r "$directory/$file_name";
	}
	die "Could not find $file_name in @directories.\n"
		. "Set CLAY_FONT_PATH to the directory that holds it.\n";
}

my $FONT_PATH = locate_font('DejaVuSansMono.ttf');
my $FONT      = Imager::Font->new(file => $FONT_PATH)
	or die "Imager font load failed ($FONT_PATH): " . Imager->errstr . "\n";

# ---------------------------------------------------------------------------
# PNG renderer
# ---------------------------------------------------------------------------

sub imager_color ($c) {
	return Imager::Color->new($c->{r}, $c->{g}, $c->{b}, $c->{a});
}

use constant PI => 4 * atan2(1, 1);

# Clay reports four corner radii; they are clamped (as CSS does) so that
# neighbouring corners never overlap.
sub corner_radii ($radius, $width, $height) {
	my @radii = map { max(0, $radius->{$_} // 0) } qw(topLeft topRight bottomRight bottomLeft);
	my ($tl, $tr, $br, $bl) = @radii;
	my $scale = min(1,
		map { $_->[0] > 0 ? $_->[1] / $_->[0] : 1 }
			[$tl + $tr, $width], [$bl + $br, $width], [$tl + $bl, $height], [$tr + $br, $height]);
	return map { $_ * $scale } @radii;
}

# The outline of a rounded rectangle as [ \@x, \@y ], clockwise, for
# Imager's polypolygon. Each corner is a quarter circle made of short
# straight segments; corners with radius 0 stay square.
sub rounded_rect_outline ($x, $y, $width, $height, @radii) {
	my ($tl, $tr, $br, $bl) = @radii;
	my @corners = (
		[$x + $tl,          $y + $tl,           $tl, 180],
		[$x + $width - $tr, $y + $tr,           $tr, 270],
		[$x + $width - $br, $y + $height - $br, $br, 0],
		[$x + $bl,          $y + $height - $bl, $bl, 90],
	);
	my (@xs, @ys);
	for my $corner (@corners) {
		my ($cx, $cy, $r, $start) = @$corner;
		my $steps = $r > 0 ? max(4, ceil($r / 2)) : 0;
		for my $step (0 .. $steps) {
			my $angle = ($start + 90 * $step / max(1, $steps)) * PI / 180;
			push @xs, $cx + $r * cos $angle;
			push @ys, $cy + $r * sin $angle;
		}
	}
	return [\@xs, \@ys];
}

# Imager's box() has no rounded corners, and its polypolygon does not
# blend translucent colours. So the outlines become an antialiased
# coverage mask, through which a block of the colour is composed onto the
# image. With 'evenodd' filling, an outline inside another cuts a hole.
sub fill_outlines ($img, $color, @outlines) {
	my @xs = map { @{ $_->[0] } } @outlines;
	my @ys = map { @{ $_->[1] } } @outlines;
	my ($left, $top) = (floor(min @xs), floor(min @ys));
	my ($width, $height) = (ceil(max @xs) - $left, ceil(max @ys) - $top);
	return if $width < 1 || $height < 1;

	my $mask = Imager->new(xsize => $width, ysize => $height, channels => 1);
	$mask->polypolygon(
		points => [ map { [ [map { $_ - $left } @{ $_->[0] }], [map { $_ - $top } @{ $_->[1] }] ] } @outlines ],
		filled => 1,
		mode   => 'evenodd',
		color  => Imager::Color->new(255, 255, 255),
	);
	my $paint = Imager->new(xsize => $width, ysize => $height, channels => 4);
	$paint->box(filled => 1, color => imager_color($color));
	$img->compose(src => $paint, mask => $mask, tx => $left, ty => $top);
	return;
}

sub draw_rectangle ($img, $cmd) {
	my $b = $cmd->{boundingBox};
	my $d = $cmd->{renderData};
	my @radii = corner_radii($d->{cornerRadius}, $b->{width}, $b->{height});
	fill_outlines($img, $d->{backgroundColor},
		rounded_rect_outline($b->{x}, $b->{y}, $b->{width}, $b->{height}, @radii));
	return;
}

# A border lies inside the bounding box: a left border 2 wide covers the
# box's two leftmost columns. It is the ring between the box's outline and
# an inner outline inset by each edge's width (whose corners are rounded
# less by that width).
sub draw_border ($img, $cmd) {
	my $b = $cmd->{boundingBox};
	my $d = $cmd->{renderData};
	my $w = $d->{width};
	my ($tl, $tr, $br, $bl) = corner_radii($d->{cornerRadius}, $b->{width}, $b->{height});
	my $inner_width  = $b->{width}  - $w->{left} - $w->{right};
	my $inner_height = $b->{height} - $w->{top}  - $w->{bottom};
	my $outer = rounded_rect_outline($b->{x}, $b->{y}, $b->{width}, $b->{height}, $tl, $tr, $br, $bl);
	return fill_outlines($img, $d->{color}, $outer)
		if $inner_width <= 0 || $inner_height <= 0;

	my @inner_radii = (
		max(0, $tl - max($w->{left},  $w->{top})),
		max(0, $tr - max($w->{right}, $w->{top})),
		max(0, $br - max($w->{right}, $w->{bottom})),
		max(0, $bl - max($w->{left},  $w->{bottom})),
	);
	my $inner = rounded_rect_outline($b->{x} + $w->{left}, $b->{y} + $w->{top},
		$inner_width, $inner_height, @inner_radii);
	fill_outlines($img, $d->{color}, $outer, $inner);
	return;
}

# Clay's text bounding box is already laid out for the configured fontSize.
# Imager's string() places the baseline at the given y, so we offset down
# from the box top by roughly the font ascent (fontSize * 0.8).
sub draw_text ($img, $cmd) {
	my $b = $cmd->{boundingBox};
	my $d = $cmd->{renderData};
	my $fs = $d->{fontSize};
	$img->string(
		font   => $FONT,
		text   => $d->{stringContents},
		x      => $b->{x},
		y      => $b->{y} + $fs * 0.8,
		size   => $fs,
		color  => imager_color($d->{textColor}),
		aa     => 1,
	);
}

sub render_to_png ($commands, $width, $height, $path) {
	my $img = Imager->new(xsize => $width, ysize => $height, channels => 4);
	$img->box(color => Imager::Color->new(0, 0, 0, 0), filled => 1);

	# Draw in array order; Clay has already sorted the commands (see
	# Clay::Manual, Writing a renderer).
	for my $cmd (@$commands) {
		my $type = $cmd->{commandType};
		if    ($type == CLAY_RENDER_COMMAND_TYPE_RECTANGLE) { draw_rectangle($img, $cmd) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_BORDER)    { draw_border($img, $cmd) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_TEXT)      { draw_text($img, $cmd) }
		# IMAGE and custom commands are intentionally ignored.
	}

	$img->write(file => $path)
		or die "Imager write failed ($path): " . $img->errstr . "\n";
}

# ---------------------------------------------------------------------------
# Demo layout
# ---------------------------------------------------------------------------

my $out = $ARGV[0] // 'out.png';
my ($W, $H) = (720, 360);

my $WHITE = [255, 255, 255, 255];

my $LOREM = 'Clay reflows this sentence to fit the card width, '
		  . 'breaking on word boundaries so each alignment value '
		  . 'can be compared side by side.';

my @ALIGN_DEMO = (
	[ 'left',   CLAY_TEXT_ALIGN_LEFT   ],
	[ 'center', CLAY_TEXT_ALIGN_CENTER ],
	[ 'right',  CLAY_TEXT_ALIGN_RIGHT  ],
);

sub label ($text, $font_size = 16) {
	return My::Text->new(
		text       => $text,
		font_size  => $font_size,
		text_color => $WHITE,
	);
}

sub build_tree () {
	my @cards;
	for my $i (0 .. 2) {
		my ($name, $align) = @{ $ALIGN_DEMO[$i] };
		my $card = My::Box->new(
			id => "card-$i",
			layout => {
				sizing           => { width => sizing_grow(), height => sizing_grow() },
				padding          => padding_all(10),
				child_gap        => 8,
				layout_direction => CLAY_TOP_TO_BOTTOM,
			},
			background_color => [225 - $i * 40, 138, 50 + $i * 30, 255],
			corner_radius    => 4,
		);
		$card->add_child(
			label("card $i ($name)"),
			My::Text->new(
				text           => $LOREM,
				font_size      => 14,
				text_color     => $WHITE,
				text_alignment => $align,
			),
		);
		push @cards, $card;
	}

	my $header = My::Box->new(
		id => 'header',
		layout => {
			sizing          => { width => sizing_grow(), height => sizing_fixed(48) },
			padding         => padding_all(12),
			child_alignment => { x => CLAY_ALIGN_X_LEFT, y => CLAY_ALIGN_Y_CENTER },
		},
		background_color => [50, 100, 200, 255],
		corner_radius    => 6,
	);
	$header->add_child(label("Clay -> PNG demo", 20));

	my $body = My::Box->new(
		id => 'body',
		layout => {
			sizing    => { width => sizing_grow(), height => sizing_grow() },
			padding   => padding_all(12),
			child_gap => 12,
		},
		background_color => $WHITE,
		border_color     => [200, 200, 210, 255],
		border_width     => 2,
		corner_radius    => 6,
	);
	$body->add_child(@cards);

	my $root = My::Box->new(
		id => 'root',
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => padding_all(16),
			child_gap        => 12,
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
		background_color => [245, 246, 250, 255],
	);
	$root->add_child($header, $body);
	return $root;
}

my $ui = Clay::UI->new(
	width        => $W,
	height       => $H,
	root         => build_tree(),
	measure_text => sub ($text, $config, $userdata) {
		my $fs   = $config->{fontSize} || 16;
		my $bbox = $FONT->bounding_box(string => $text, size => $fs);
		return {
			width  => $bbox ? $bbox->advance_width : length($text) * $fs * 0.6,
			height => $fs,
		};
	},
	error_handler => sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);

my $commands = $ui->render;
render_to_png($commands, $W, $H, $out);
print "Wrote $out\n";

# Tear down in a defined order so Imager's font is freed before global
# destruction touches it. The Clay context retains the measure-text closure
# that captures $FONT; if Perl frees Imager state first the closure crashes.
undef $ui;
undef $FONT;
