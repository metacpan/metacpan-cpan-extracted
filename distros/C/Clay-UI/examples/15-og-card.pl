#!/usr/bin/env perl

# 15-og-card.pl - Render a 1200x630 Open Graph card to PNG with Imager.
#
# An Open Graph card is the preview image social media sites show for a
# shared link. Clay::UI lays it out; Imager draws it. The card is built
# from the %POST hash below: site name and logo, a title that wraps over
# at most three lines, a description, tag pills, the author with an
# avatar and the date. Text is measured with the real fonts, so the
# layout matches what Imager draws. The title shrinks until it fits three
# lines (and is shortened with "..." if even the smallest size is too big).
# Writes the PNG to the path given as first argument (out.png in the
# current directory by default); a second argument replaces the title.
#
# Shows:
#   - a measure_text callback built on Imager font bounding boxes, with
#     several fonts selected by font_id, honouring line_height and
#     letter_spacing
#   - fitting text: lay out, read the widget's bounding box, retry smaller
#   - FIXED, GROW, FIT and PERCENT sizing, padding, child_gap,
#     child_alignment, corner radii and borders
#   - a wrapping tag row and an avatar with a badge stacked on top of it
#   - widget classes with contributors of their own (image, aspect ratio,
#     clip, overlay colour) next to the ones Clay::UI::Box provides
#   - a reusable Imager renderer for rectangles, borders, text, images,
#     clipping and overlay colours, antialiased, with per-corner radii
#
# Features: Clay::UI, Clay::UI::Box, Clay::UI::Text, bounding_box, measure_text, check_struct, fontId, fontSize, lineHeight, letterSpacing, CLAY_TEXT_WRAP_WORDS, sizing_fixed, sizing_grow, sizing_fit, sizing_percent, padding, child_gap, child_alignment, line_gap, CLAY_LEFT_TO_RIGHT_WRAP, CLAY_BACK_TO_FRONT, corner_radius, border_color, border_width, image_data, imageData, aspect_ratio, clip, child_offset, overlay_color, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER, CLAY_RENDER_COMMAND_TYPE_TEXT, CLAY_RENDER_COMMAND_TYPE_IMAGE, CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END
#
# Requires: Imager with PNG support (Imager::File::PNG) and FreeType
#   (Imager::Font::FT2), and the DejaVu Sans fonts (DejaVuSans.ttf,
#   DejaVuSans-Bold.ttf). Set CLAY_FONT_PATH to a directory holding them
#   if they are not in one of the places probed below.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/15-og-card.pl [out.png] [title]

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Imager;
use List::Util qw(min max sum0);
use POSIX qw(floor ceil);
use Clay::XS qw(:all);
use Clay::UI;

# ---------------------------------------------------------------------------
# The card's content
# ---------------------------------------------------------------------------

my %POST = (
	site_name    => 'Layout Notes',
	title        => 'Laying out pixel-perfect preview cards with Perl and Clay',
	description  => 'Measure text with real fonts, let Clay wrap and size everything, '
		. 'and draw the result with Imager - no browser needed.',
	author       => 'Dana Example',
	date         => '2026-10-04',
	reading_time => 7,
	tags         => [qw(perl clay imager layout)],
	accent       => '#F5A524',
);

my ($CARD_WIDTH, $CARD_HEIGHT) = (1200, 630);
my $TITLE_MAX_LINES = 3;

# Largest first: the title gets the first size that fits $TITLE_MAX_LINES.
my @TITLE_FONT_SIZES = (80, 74, 68, 62, 56, 50, 46);

my %CONTENT_PADDING = (left => 72, right => 72, top => 52, bottom => 48);

# ---------------------------------------------------------------------------
# Parsing the content (once, at the boundary)
# ---------------------------------------------------------------------------

sub parse_hex_color ($hex) {
	my ($r, $g, $b) = $hex =~ /\A#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\z/i
		or die "Not a #RRGGBB colour: '$hex'\n";
	return [hex $r, hex $g, hex $b, 255];
}

my @MONTH_NAMES = qw(January February March April May June July August September October November December);

sub format_date ($iso) {
	my ($year, $month, $day) = $iso =~ /\A(\d{4})-(\d{2})-(\d{2})\z/
		or die "Not a YYYY-MM-DD date: '$iso'\n";
	die "Month out of range in '$iso'\n" unless $month >= 1 && $month <= 12;
	return sprintf '%s %d, %d', $MONTH_NAMES[$month - 1], $day, $year;
}

# Mixes two opaque colours: 0 gives $from, 1 gives $to.
sub mix_color ($from, $to, $amount) {
	return [ (map { int($from->[$_] + ($to->[$_] - $from->[$_]) * $amount + 0.5) } 0 .. 2), 255 ];
}

my $output_path = $ARGV[0] // 'out.png';
my $title_text = $ARGV[1] // $POST{title};
die "The title must not be empty\n" unless $title_text =~ /\S/;

my $ACCENT     = parse_hex_color($POST{accent});
my $BACKGROUND = [12, 17, 29, 255];
my $TEXT       = [241, 245, 249, 255];
my $MUTED      = [148, 163, 184, 255];
my $TAG_FILL   = mix_color($BACKGROUND, $ACCENT, 0.14);
my $TAG_EDGE   = mix_color($BACKGROUND, $ACCENT, 0.45);
my $DATE_TEXT  = format_date($POST{date});

# ---------------------------------------------------------------------------
# Fonts: font_id in a text widget selects one of these
# ---------------------------------------------------------------------------

use constant {
	FONT_REGULAR => 0,
	FONT_BOLD    => 1,
};

my %FONT_FILES = (
	FONT_REGULAR() => 'DejaVuSans.ttf',
	FONT_BOLD()    => 'DejaVuSans-Bold.ttf',
);

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

sub load_fonts () {
	my %fonts;
	for my $font_id (sort keys %FONT_FILES) {
		my $path = locate_font($FONT_FILES{$font_id});
		$fonts{$font_id} = Imager::Font->new(file => $path)
			or die "Imager could not load $path: " . Imager->errstr . "\n";
	}
	return \%fonts;
}

# ---------------------------------------------------------------------------
# Text metrics, shared by measure_text and the renderer so both agree
# ---------------------------------------------------------------------------

# Width of $text with $letter_spacing added after every character. Without
# letter spacing one bounding box covers the string (and keeps kerning).
sub text_advance ($font, $size, $text, $letter_spacing) {
	return 0 if $text eq '';
	return $font->bounding_box(string => $text, size => $size)->advance_width
		unless $letter_spacing;
	return sum0(map { $font->bounding_box(string => $_, size => $size)->advance_width } split //, $text)
		+ $letter_spacing * length $text;
}

# ( ascent, height ) of the font at $size: the same for every string.
sub font_metrics ($font, $size) {
	my $box = $font->bounding_box(string => 'Hg', size => $size);
	return ($box->global_ascent, $box->global_ascent - $box->global_descent);
}

# Clay calls this for every word (and space) it lays out. Clay uses the
# returned height for single lines and lineHeight, when set, for wrapped
# lines; see Clay::UI, measure_text.
sub make_text_measurer ($fonts) {
	return sub ($text, $config, $userdata) {
		my $font = $fonts->{ $config->{fontId} }
			// die "measure_text: no font for fontId $config->{fontId}\n";
		my (undef, $height) = font_metrics($font, $config->{fontSize});
		return {
			width  => text_advance($font, $config->{fontSize}, $text, $config->{letterSpacing}),
			height => $config->{lineHeight} || $height,
		};
	};
}

# ---------------------------------------------------------------------------
# Images, generated in the script; render commands carry their integer key
# ---------------------------------------------------------------------------

use constant {
	IMAGE_LOGO   => 1,
	IMAGE_AVATAR => 2,
};

sub imager_color ($rgba) {
	return Imager::Color->new(@$rgba);
}

# A square logo: three blocks of a page layout on the accent colour.
sub make_logo_image ($accent) {
	my $size  = 256;
	my $image = Imager->new(xsize => $size, ysize => $size, channels => 4);
	my $ink   = imager_color([255, 255, 255, 235]);
	$image->box(filled => 1, color => imager_color($accent));
	$image->box(filled => 1, color => $ink, xmin => 48,  ymin => 48,  xmax => 207, ymax => 87);
	$image->box(filled => 1, color => $ink, xmin => 48,  ymin => 108, xmax => 103, ymax => 207);
	$image->box(filled => 1, color => imager_color([255, 255, 255, 150]), xmin => 124, ymin => 108, xmax => 207, ymax => 207);
	return $image;
}

# A portrait placeholder: a head and shoulders over a vertical gradient.
sub make_avatar_image ($accent) {
	my $size  = 256;
	my $image = Imager->new(xsize => $size, ysize => $size, channels => 4);
	my $top    = mix_color([70, 80, 110, 255], $accent, 0.35);
	my $bottom = [30, 36, 54, 255];
	for my $y (0 .. $size - 1) {
		$image->line(x1 => 0, x2 => $size - 1, y1 => $y, y2 => $y,
			color => imager_color(mix_color($top, $bottom, $y / ($size - 1))));
	}
	my $skin = imager_color([236, 200, 170, 255]);
	$image->circle(x => 128, y => 104, r => 50, color => $skin, aa => 1);
	$image->circle(x => 128, y => 292, r => 120, color => imager_color(mix_color([235, 238, 245, 255], $accent, 0.25)), aa => 1);
	return $image;
}

# ---------------------------------------------------------------------------
# Widget classes
# ---------------------------------------------------------------------------

use Object::Pad 0.800;
use Clay::UI::Box;
use Clay::UI::Text;

class OG::Box :strict(params) :does(Clay::UI::Box) {}

class OG::Text :strict(params) :does(Clay::UI::Text) {}

# A box that clips its children. Its clip slice is passed to Clay as is
# (no scrolling: see Clay::UI, NOTES), so child_offset shifts the children
# by a fixed amount.
class OG::ClipBox :strict(params) :does(Clay::UI::Box) {
	use Clay::XS qw(check_struct);

	field $clip :param;

	ADJUST {
		die "OG::ClipBox: clip must be a hash reference\n" unless ref $clip eq 'HASH';
		my @unknown = grep { !/\A(?:horizontal|vertical|child_offset)\z/ } sort keys %$clip;
		die "OG::ClipBox: unknown clip keys: @unknown\n" if @unknown;
		check_struct('Clay_ClipElementConfig', {
			horizontal  => $clip->{horizontal},
			vertical    => $clip->{vertical},
			childOffset => $clip->{child_offset},
		}, 'clip');
		$clip = { %$clip };
	}

	method contribute_clip ($config) {
		$config->{clip} = { %$clip };
		return;
	}
}

# An image element: Clay only passes image_key through as imageData, the
# renderer looks the image up. aspect_ratio lets Clay derive the height
# from the width; overlay_color tints the image and everything inside it.
class OG::Image :strict(params) :does(Clay::UI::Box) {
	use Clay::XS qw(check_struct);

	field $image_key     :param;
	field $aspect_ratio  :param;
	field $overlay_color :param = undef;

	ADJUST {
		check_struct('Clay_ImageElementConfig',       { imageData   => $image_key },    'image_key');
		check_struct('Clay_AspectRatioElementConfig', { aspectRatio => $aspect_ratio }, 'aspect_ratio');
		check_struct('Clay_Color', $overlay_color, 'overlay_color') if defined $overlay_color;
		die "OG::Image: image_key must not be 0 (Clay draws no image for it)\n" unless $image_key;
		$overlay_color = [@$overlay_color] if defined $overlay_color;
	}

	method contribute_image ($config) {
		$config->{image}        = { image_data => $image_key };
		$config->{aspect_ratio} = { aspect_ratio => $aspect_ratio };
		return;
	}

	method contribute_overlay_color ($config) {
		return unless defined $overlay_color;
		$config->{overlay_color} = [@$overlay_color];
		return;
	}
}

# ---------------------------------------------------------------------------
# Build the tree
# ---------------------------------------------------------------------------

sub text_widget (%args) {
	return OG::Text->new(font_id => FONT_REGULAR, text_color => $TEXT, %args);
}

sub header_row () {
	my $site = OG::Box->new(
		layout => {
			child_gap       => 16,
			child_alignment => { y => CLAY_ALIGN_Y_CENTER },
		},
	);
	$site->add_child(
		OG::Image->new(
			image_key     => IMAGE_LOGO,
			aspect_ratio  => 1,
			layout        => { sizing => { width => sizing_fixed(48) } },
			corner_radius => 12,
		),
		text_widget(text => $POST{site_name}, font_id => FONT_BOLD, font_size => 26),
	);

	my $reading_time = OG::Box->new(
		layout => {
			padding => { left => 18, right => 18, top => 9, bottom => 9 },
		},
		border_color  => $TAG_EDGE,
		border_width  => 2,
		corner_radius => 20,
	);
	$reading_time->add_child(text_widget(
		text           => uc "$POST{reading_time} min read",
		font_id        => FONT_BOLD,
		font_size      => 16,
		letter_spacing => 2,
		text_color     => $ACCENT,
	));

	# The bottom padding sets the header off from the title.
	my $row = OG::Box->new(
		layout => {
			sizing          => { width => sizing_grow() },
			padding         => { bottom => 12 },
			child_alignment => { y => CLAY_ALIGN_Y_CENTER },
		},
	);
	$row->add_child(
		$site,
		OG::Box->new(layout => { sizing => { width => sizing_grow() } }),
		$reading_time,
	);
	return $row;
}

# Clay::UI can report the size of element widgets only, so the title text
# sits in a box whose height (FIT) follows the wrapped text.
sub title_block ($title) {
	my $block = OG::Box->new(
		layout => { sizing => { width => sizing_percent(0.94) } },
	);
	$block->add_child($title);
	return $block;
}

# Two lines at most: a longer description is clipped by the box.
sub description_block () {
	my $line_height = 38;
	my $block = OG::ClipBox->new(
		clip   => { horizontal => 0, vertical => 1 },
		layout => {
			sizing => {
				width  => sizing_percent(0.82),
				height => sizing_fit(0, 2 * $line_height),
			},
		},
	);
	$block->add_child(text_widget(
		text        => $POST{description},
		font_size   => 26,
		line_height => $line_height,
		text_color  => $MUTED,
		wrap_mode   => CLAY_TEXT_WRAP_WORDS,
	));
	return $block;
}

sub tag_pill ($name) {
	my $pill = OG::Box->new(
		layout => {
			padding => { left => 14, right => 14, top => 7, bottom => 7 },
		},
		background_color => $TAG_FILL,
		border_color     => $TAG_EDGE,
		border_width     => 1,
		corner_radius    => 8,
	);
	$pill->add_child(text_widget(
		text           => "#$name",
		font_size      => 19,
		letter_spacing => 1,
		text_color     => mix_color($ACCENT, $TEXT, 0.35),
	));
	return $pill;
}

# The pills take the rest of the footer, aligned to the right, and flow
# onto further lines when they do not fit one.
sub tag_row () {
	my $row = OG::Box->new(
		layout => {
			sizing           => { width => sizing_grow() },
			padding          => { left => 24 },
			child_gap        => 12,
			line_gap         => 12,
			child_alignment  => { x => CLAY_ALIGN_X_RIGHT, y => CLAY_ALIGN_Y_CENTER },
			layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
		},
	);
	$row->add_child(map { tag_pill($_) } @{ $POST{tags} });
	return $row;
}

# A stack (CLAY_BACK_TO_FRONT): the avatar, then a badge over its bottom
# right corner. The badge is a stack too, centering its check mark.
sub avatar_with_badge () {
	my $badge = OG::Box->new(
		layout => {
			sizing           => { width => sizing_fixed(26), height => sizing_fixed(26) },
			child_alignment  => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
			layout_direction => CLAY_BACK_TO_FRONT,
		},
		background_color => $ACCENT,
		border_color     => $BACKGROUND,
		border_width     => 3,
		corner_radius    => 13,
	);
	$badge->add_child(text_widget(
		text       => "\x{2713}",
		font_id    => FONT_BOLD,
		font_size  => 13,
		text_color => $BACKGROUND,
	));

	my $stack = OG::Box->new(
		layout => {
			child_alignment  => { x => CLAY_ALIGN_X_RIGHT, y => CLAY_ALIGN_Y_BOTTOM },
			layout_direction => CLAY_BACK_TO_FRONT,
		},
	);
	$stack->add_child(
		OG::Image->new(
			image_key     => IMAGE_AVATAR,
			aspect_ratio  => 1,
			layout        => { sizing => { width => sizing_fixed(72) } },
			corner_radius => 36,
			border_color  => $ACCENT,
			border_width  => 3,
		),
		$badge,
	);
	return $stack;
}

sub footer_row () {
	my $byline = OG::Box->new(
		layout => {
			child_gap        => 6,
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
	);
	$byline->add_child(
		text_widget(text => $POST{author}, font_id => FONT_BOLD, font_size => 25),
		text_widget(text => $DATE_TEXT, font_size => 20, text_color => $MUTED),
	);

	my $row = OG::Box->new(
		layout => {
			sizing          => { width => sizing_grow() },
			child_gap       => 20,
			child_alignment => { y => CLAY_ALIGN_Y_CENTER },
		},
	);
	$row->add_child(avatar_with_badge(), $byline, tag_row());
	return $row;
}

# The logo, large and dimmed into the background by its overlay colour,
# bleeding off the bottom right corner: the clip box shifts it outwards
# with child_offset and cuts it at the card's edge.
sub watermark () {
	my $clip = OG::ClipBox->new(
		clip   => { horizontal => 1, vertical => 1, child_offset => { x => 120, y => 140 } },
		layout => {
			sizing          => { width => sizing_grow(), height => sizing_grow() },
			child_alignment => { x => CLAY_ALIGN_X_RIGHT, y => CLAY_ALIGN_Y_BOTTOM },
		},
	);
	$clip->add_child(OG::Image->new(
		image_key     => IMAGE_LOGO,
		aspect_ratio  => 1,
		layout        => { sizing => { width => sizing_fixed(440) } },
		corner_radius => 96,
		overlay_color => [@$BACKGROUND[0 .. 2], 240],
	));
	return $clip;
}

# Returns the widgets the script needs again: the root, the title text
# (the one to fit) and the footer (the last thing that must fit the card).
sub build_card ($title_text) {
	my $title = text_widget(
		text      => $title_text,
		font_id   => FONT_BOLD,
		wrap_mode => CLAY_TEXT_WRAP_WORDS,
	);

	# The column clips vertically, which also stops Clay from compressing
	# its children when they overflow: the title block keeps the height of
	# all its lines, and fit_title can count them.
	my $content = OG::ClipBox->new(
		clip   => { horizontal => 0, vertical => 1 },
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			padding          => \%CONTENT_PADDING,
			child_gap        => 22,
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
	);
	my $footer = footer_row();
	$content->add_child(
		header_row(),
		title_block($title),
		description_block(),
		OG::Box->new(layout => { sizing => { height => sizing_grow() } }),
		$footer,
	);

	my $page = OG::Box->new(
		layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
	);
	$page->add_child(
		OG::Box->new(
			layout           => { sizing => { width => sizing_fixed(14), height => sizing_grow() } },
			background_color => $ACCENT,
		),
		$content,
	);

	# Back to front: the watermark first, the content over it.
	my $root = OG::Box->new(
		id     => 'card',
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			layout_direction => CLAY_BACK_TO_FRONT,
		},
		background_color => $BACKGROUND,
	);
	$root->add_child(watermark(), $page);
	return { root => $root, title => $title, footer => $footer };
}

# ---------------------------------------------------------------------------
# Fitting the title: lay out, measure, retry
# ---------------------------------------------------------------------------

sub title_line_height ($font_size) {
	return int($font_size * 1.14 + 0.5);
}

# Lays the card out with the title at $font_size. Returns the render
# commands, or nothing when the layout does not fit: the title took more
# than $TITLE_MAX_LINES lines (its block is as tall as all of them), or
# the footer was pushed past the bottom padding.
sub lay_out_title ($ui, $card, $font_size) {
	my $line_height = title_line_height($font_size);
	$card->{title}->font_size($font_size);
	$card->{title}->line_height($line_height);
	my $commands = $ui->render;

	my $title_box  = $ui->bounding_box($card->{title}->parent) // die "The title block was not laid out\n";
	my $footer_box = $ui->bounding_box($card->{footer})        // die "The footer was not laid out\n";
	my $lines      = int($title_box->{height} / $line_height + 0.5);
	my $footer_end = $footer_box->{y} + $footer_box->{height};
	return if $lines > $TITLE_MAX_LINES || $footer_end > $CARD_HEIGHT - $CONTENT_PADDING{bottom};
	return $commands;
}

# Tries each size in @TITLE_FONT_SIZES; when even the smallest does not
# fit, drops words from the end and adds "...". Returns the commands of
# the frame that fits and the font size used.
sub fit_title ($ui, $card) {
	for my $font_size (@TITLE_FONT_SIZES) {
		my $commands = lay_out_title($ui, $card, $font_size);
		return ($commands, $font_size) if $commands;
	}

	my $font_size = $TITLE_FONT_SIZES[-1];
	my @words     = split ' ', $card->{title}->text;
	while (@words > 1) {
		pop @words;
		$card->{title}->text(join(' ', @words) . '...');
		my $commands = lay_out_title($ui, $card, $font_size);
		return ($commands, $font_size) if $commands;
	}
	die "The card does not fit even with a one-word title\n";
}

# ---------------------------------------------------------------------------
# Imager renderer
# ---------------------------------------------------------------------------

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
# Imager's polypolygon. Corners with radius 0 stay square.
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

# The drawing state: a stack of layers (overlay colours draw into a layer
# of their own) and a stack of clip rectangles (scissors). Commands draw on
# the canvas: the top layer, masked to the top clip rectangle. A masked
# image counts coordinates from the clip rectangle's corner, so the canvas
# carries that offset.
sub current_canvas ($state) {
	my $layer = $state->{layers}[-1]{image};
	my $clip  = $state->{clips}[-1];
	return { image => $layer, left => 0, top => 0 } unless $clip;
	return {
		image => $layer->masked(%$clip),
		left  => $clip->{left},
		top   => $clip->{top},
	};
}

# Imager's polypolygon does not blend colours with transparency, so the
# outlines become an antialiased coverage mask, through which a block of
# the colour is composed onto the canvas.
sub fill_outlines ($canvas, $color, @outlines) {
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
	$canvas->{image}->compose(
		src  => $paint,
		mask => $mask,
		tx   => $left - $canvas->{left},
		ty   => $top  - $canvas->{top},
	);
	return;
}

sub color_of ($c) {
	return [$c->{r}, $c->{g}, $c->{b}, $c->{a}];
}

sub draw_rectangle ($canvas, $cmd) {
	my $b = $cmd->{boundingBox};
	my $d = $cmd->{renderData};
	my @radii = corner_radii($d->{cornerRadius}, $b->{width}, $b->{height});
	fill_outlines($canvas, color_of($d->{backgroundColor}),
		rounded_rect_outline($b->{x}, $b->{y}, $b->{width}, $b->{height}, @radii));
	return;
}

# A border is the ring between the outer outline and an inner one inset by
# each side's width; evenodd filling leaves the inside empty.
sub draw_border ($canvas, $cmd) {
	my $b = $cmd->{boundingBox};
	my $d = $cmd->{renderData};
	my $w = $d->{width};
	my ($tl, $tr, $br, $bl) = corner_radii($d->{cornerRadius}, $b->{width}, $b->{height});
	my $inner_width  = $b->{width}  - $w->{left} - $w->{right};
	my $inner_height = $b->{height} - $w->{top}  - $w->{bottom};
	my $outer = rounded_rect_outline($b->{x}, $b->{y}, $b->{width}, $b->{height}, $tl, $tr, $br, $bl);
	return fill_outlines($canvas, color_of($d->{color}), $outer)
		if $inner_width <= 0 || $inner_height <= 0;

	my @inner_radii = (
		max(0, $tl - max($w->{left},  $w->{top})),
		max(0, $tr - max($w->{right}, $w->{top})),
		max(0, $br - max($w->{right}, $w->{bottom})),
		max(0, $bl - max($w->{left},  $w->{bottom})),
	);
	my $inner = rounded_rect_outline($b->{x} + $w->{left}, $b->{y} + $w->{top},
		$inner_width, $inner_height, @inner_radii);
	fill_outlines($canvas, color_of($d->{color}), $outer, $inner);
	return;
}

# Clay gives one command per laid-out line, with the line's box. The
# glyphs are centred vertically in it (it is lineHeight tall for wrapped
# text). With letter spacing each character is drawn on its own, matching
# text_advance.
sub draw_text ($canvas, $cmd, $fonts) {
	my $b    = $cmd->{boundingBox};
	my $d    = $cmd->{renderData};
	my $font = $fonts->{ $d->{fontId} } // die "render_to_imager: no font for fontId $d->{fontId}\n";
	my $size = $d->{fontSize};
	my ($ascent, $height) = font_metrics($font, $size);
	my $baseline = $b->{y} + ($b->{height} - $height) / 2 + $ascent - $canvas->{top};
	my $x        = $b->{x} - $canvas->{left};
	my %pen      = (font => $font, size => $size, color => imager_color(color_of($d->{textColor})), aa => 1, y => $baseline);

	return $canvas->{image}->string(%pen, x => $x, text => $d->{stringContents})
		unless $d->{letterSpacing};
	for my $char (split //, $d->{stringContents}) {
		$canvas->{image}->string(%pen, x => $x, text => $char);
		$x += text_advance($font, $size, $char, $d->{letterSpacing});
	}
	return;
}

# Scales the image to the element's box; rounded corners become an
# antialiased mask that limits where the image shows.
sub draw_image ($canvas, $cmd, $images) {
	my $b     = $cmd->{boundingBox};
	my $d     = $cmd->{renderData};
	my $image = $images->{ $d->{imageData} } // die "render_to_imager: no image for imageData $d->{imageData}\n";
	my ($left, $top) = (floor($b->{x} + 0.5), floor($b->{y} + 0.5));
	my ($width, $height) = (floor($b->{width} + 0.5), floor($b->{height} + 0.5));
	return if $width < 1 || $height < 1;

	my $scaled = $image->scale(xpixels => $width, ypixels => $height, type => 'nonprop', qtype => 'mixing');
	my $mask   = Imager->new(xsize => $width, ysize => $height, channels => 1);
	$mask->polypolygon(
		points => [ rounded_rect_outline(0, 0, $width, $height, corner_radii($d->{cornerRadius}, $width, $height)) ],
		filled => 1,
		color  => Imager::Color->new(255, 255, 255),
	);
	$canvas->{image}->compose(
		src  => $scaled,
		mask => $mask,
		tx   => $left - $canvas->{left},
		ty   => $top  - $canvas->{top},
	);
	return;
}

# Clips nest: a new rectangle is cut down to the one it is inside.
sub start_scissor ($state, $cmd) {
	my $b      = $cmd->{boundingBox};
	my $outer  = $state->{clips}[-1] // { left => 0, top => 0, right => $state->{width}, bottom => $state->{height} };
	my %clip = (
		left   => max($outer->{left},   floor($b->{x})),
		top    => max($outer->{top},    floor($b->{y})),
		right  => min($outer->{right},  ceil($b->{x} + $b->{width})),
		bottom => min($outer->{bottom}, ceil($b->{y} + $b->{height})),
	);
	$clip{right}  = $clip{left} if $clip{right}  < $clip{left};
	$clip{bottom} = $clip{top}  if $clip{bottom} < $clip{top};
	push @{ $state->{clips} }, \%clip;
	return;
}

sub start_overlay ($state, $cmd) {
	my $layer = Imager->new(xsize => $state->{width}, ysize => $state->{height}, channels => 4);
	push @{ $state->{layers} }, { image => $layer, color => color_of($cmd->{renderData}{color}) };
	return;
}

# The overlay colour is blended over the layer's colours, the layer keeps
# its own transparency, and the tinted layer is drawn onto the one below.
sub end_overlay ($state) {
	die "render_to_imager: overlay end without start\n" if @{ $state->{layers} } < 2;
	my $layer  = pop @{ $state->{layers} };
	my $tinted = $layer->{image}->copy;
	my $paint  = Imager->new(xsize => $state->{width}, ysize => $state->{height}, channels => 4);
	$paint->box(filled => 1, color => imager_color($layer->{color}));
	$tinted->compose(src => $paint);
	my $result = Imager->combine(src => [$tinted, $tinted, $tinted, $layer->{image}], channels => [0, 1, 2, 3]);
	my $canvas = current_canvas($state);
	$canvas->{image}->rubthrough(src => $result, tx => 0, ty => 0,
		src_minx => $canvas->{left}, src_miny => $canvas->{top});
	return;
}

# Draws Clay's render commands onto $imager. $fonts maps fontId to an
# Imager::Font, $images maps imageData to an Imager image. Clay returns
# the commands in drawing order, so they are drawn as they come.
sub render_to_imager ($commands, $imager, $fonts, $images) {
	my %state = (
		width  => $imager->getwidth,
		height => $imager->getheight,
		layers => [ { image => $imager } ],
		clips  => [],
	);
	for my $cmd (@$commands) {
		my $type = $cmd->{commandType};
		if    ($type == CLAY_RENDER_COMMAND_TYPE_RECTANGLE)           { draw_rectangle(current_canvas(\%state), $cmd) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_BORDER)              { draw_border(current_canvas(\%state), $cmd) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_TEXT)                { draw_text(current_canvas(\%state), $cmd, $fonts) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_IMAGE)               { draw_image(current_canvas(\%state), $cmd, $images) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START)       { start_scissor(\%state, $cmd) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END)         { pop @{ $state{clips} } }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START) { start_overlay(\%state, $cmd) }
		elsif ($type == CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END)   { end_overlay(\%state) }
		# CLAY_RENDER_COMMAND_TYPE_CUSTOM: this card declares none.
	}
	die "render_to_imager: unbalanced overlay commands\n" if @{ $state{layers} } != 1;
	return $imager;
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

my $fonts  = load_fonts();
my %images = (
	IMAGE_LOGO()   => make_logo_image($ACCENT),
	IMAGE_AVATAR() => make_avatar_image($ACCENT),
);

my $card_widgets = build_card($title_text);
my $ui = Clay::UI->new(
	width        => $CARD_WIDTH,
	height       => $CARD_HEIGHT,
	root         => $card_widgets->{root},
	measure_text => make_text_measurer($fonts),
);

my ($commands, $title_size) = fit_title($ui, $card_widgets);

my $card = Imager->new(xsize => $CARD_WIDTH, ysize => $CARD_HEIGHT, channels => 3);
render_to_imager($commands, $card, $fonts, \%images);
$card->write(file => $output_path)
	or die "Could not write $output_path: " . $card->errstr . "\n";

printf "Wrote %s (%dx%d), title at %dpx: \"%s\"\n",
	$output_path, $CARD_WIDTH, $CARD_HEIGHT, $title_size, $card_widgets->{title}->text;

# The Clay context holds the measure_text closure, which holds the fonts:
# drop the UI before the fonts so nothing is freed during global
# destruction in the wrong order.
undef $ui;
undef $fonts;
