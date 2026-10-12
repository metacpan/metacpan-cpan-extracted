#!/usr/bin/env perl

# 13-ui-scroll-floating.pl - A scrolling file list with a floating tooltip.
#
# A list of 30 files sits in a scroll container, below a strip of folder
# names that scrolls sideways. Scripted input scrolls the list with the
# wheel, by dragging and with scroll_to, wheels the strip sideways, and
# moves the pointer over rows: the hovered row lights up and a floating
# tooltip with the file size attaches to it. A log prints scroll
# positions, sizes and positions. Without an argument the last frame goes
# to stdout as SVG and the log to STDERR; with a path the SVG is written
# there and the log goes to stdout.
#
# Shows:
#   - a scroll container widget class and its OnScroll event
#   - wheel scrolling, drag scrolling with momentum, and scrolling from code
#   - a container that scrolls horizontally only
#   - reading a scroll container's position, viewport and content size
#   - a floating tooltip attached to the hovered row and removed again
#   - mapping render commands back to the widgets that produced them
#   - an SVG renderer that clips scroll containers (scissor commands)
#
# Features: Clay::UI::Role::Layout::HasScroll, horizontal, vertical, OnScroll, delta_x, delta_y, scroll_delta, enable_drag_scrolling, delta_time, scroll_state, scroll_to, bounding_box, Clay::UI::Box, Clay::UI::Text, floating, attach_to, attach_points, offset, z_index, pointer_capture_mode, CLAY_ATTACH_TO_PARENT, CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH, Clay::UI::Role::Interaction::Hoverable, OnHoverStart, OnHoverStopped, background_color, add_child, remove_child, widget_for, userData, CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/13-ui-scroll-floating.pl [out.svg]

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Enum::Result;
use Clay::UI::Role::Layout::HasScroll;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasBackground;
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Text;

# Clay::UI ships roles, not classes: each widget class is one line that
# composes the role it needs (see Clay::Manual, GETTING STARTED).
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}

# ---- Output ----
#
# The SVG goes to the path given as argument, or to stdout. The log goes
# wherever the SVG does not, so stdout never mixes the two.

my $OUTPUT = shift @ARGV;
my $LOG    = defined $OUTPUT ? \*STDOUT : \*STDERR;

# ---- Widget classes ----
#
# HasScroll makes a widget a scroll container: Clay::UI clips it, moves its
# children by Clay's scroll offset every frame and sends it OnScroll when
# its position changed. HasScroll requires an id (Clay keeps the scroll
# position per element id) and brings children (Container) with it.
# See Clay::Manual, THE LAYOUT MODEL, "Clipping and scrolling".

class Files::List :strict(params)
	:does(Clay::UI::Role::Layout::HasScroll)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasBackground)
{}

# One row of the list. Clay::UI::Box already composes HasFloating, which is
# what the tooltip below uses; Hoverable adds the hover events.

class Files::Row :strict(params)
	:does(Clay::UI::Box)
	:does(Clay::UI::Role::Interaction::Hoverable)
{
	field $file_name :param :reader;
	field $size_kb   :param :reader;
}

# ---- Build the tree ----

my $ROW_HEIGHT = 24;
my $ROW_FILL   = [245, 245, 248, 255];
my $HOVER_FILL = [205, 220, 250, 255];

sub log_line ($format, @args) {
	printf {$LOG} "$format\n", @args;
	return;
}

sub file_row ($index) {
	my $row = Files::Row->new(
		file_name => sprintf('report-%02d.txt', $index),
		size_kb   => 3 * $index + 7,
		layout    => {
			sizing          => { width => sizing_grow(), height => sizing_fixed($ROW_HEIGHT) },
			padding         => { left => 8, right => 8 },
			child_alignment => { y => CLAY_ALIGN_Y_CENTER },
		},
		background_color => $ROW_FILL,
	);
	$row->add_child(My::Text->new(text => $row->file_name, font_size => 14));
	return $row;
}

# The tooltip floats: it takes no space in its parent's layout and is drawn
# above it. attach_to => CLAY_ATTACH_TO_PARENT places it relative to the
# row it is a child of; attach_points pins its left centre to the row's
# right centre. PASSTHROUGH lets the pointer reach the widgets below it.
# See Clay::Manual, THE LAYOUT MODEL, "Floating elements".
sub build_tooltip () {
	my $tooltip = My::Box->new(
		id       => 'tooltip',
		layout   => { padding => padding_all(6) },
		floating => {
			attach_to            => CLAY_ATTACH_TO_PARENT,
			attach_points        => { element => CLAY_ATTACH_POINT_LEFT_CENTER, parent => CLAY_ATTACH_POINT_RIGHT_CENTER },
			offset               => { x => 12, y => 0 },
			z_index              => 10,
			pointer_capture_mode => CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
		},
		background_color => [40, 40, 50, 240],
		corner_radius    => 4,
	);
	$tooltip->add_child(My::Text->new(text => '', font_size => 12, text_color => [255, 255, 255, 255]));
	return $tooltip;
}

my $list = Files::List->new(
	id     => 'files',
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_fixed(200), height => sizing_fixed(200) },
		child_gap        => 1,
	},
	background_color => [220, 220, 228, 255],
);
my @rows = map { file_row($_) } 1 .. 30;
$list->add_child(@rows);

my $tooltip = build_tooltip();

# A second scroll container of the same class: one row of folder names
# that scrolls sideways only (horizontal => 1, vertical => 0).
sub folder_chip ($name) {
	my $chip = My::Box->new(
		layout           => { padding => { left => 6, right => 6, top => 4, bottom => 4 } },
		background_color => [205, 215, 235, 255],
		corner_radius    => 4,
	);
	$chip->add_child(My::Text->new(text => $name, font_size => 12));
	return $chip;
}

my $folders = Files::List->new(
	id         => 'folders',
	horizontal => 1,
	vertical   => 0,
	layout     => {
		sizing    => { width => sizing_fixed(200), height => sizing_fixed(24) },
		child_gap => 4,
	},
	background_color => [235, 235, 240, 255],
);
$folders->add_child(map { folder_chip($_) } qw(home projects clay reports 2026 october drafts));

my $root = My::Box->new(
	id     => 'page',
	layout => {
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		layout_direction => CLAY_TOP_TO_BOTTOM,
		padding          => padding_all(20),
		child_gap        => 10,
	},
	background_color => [255, 255, 255, 255],
);
$root->add_child(My::Text->new(text => 'Files', font_size => 18), $folders, $list);

# ---- Listeners ----
#
# The listeners move one tooltip widget from row to row. Hover events fire
# OnHoverStopped (old row) before OnHoverStart (new row) within a frame, so
# the tooltip is always free to attach when the new row asks for it. The
# changes show in the frame that reported the hover.

for my $row (@rows) {
	$row->on(OnHoverStart => sub ($event) {
		my $hovered = $event->target;
		log_line('  OnHoverStart   %s', $hovered->file_name);
		$hovered->background_color($HOVER_FILL);
		$tooltip->children->[0]->text(sprintf '%s: %d KB', $hovered->file_name, $hovered->size_kb);
		$hovered->add_child($tooltip);
		return Clay::UI::Enum::Result->HANDLED;
	});
	$row->on(OnHoverStopped => sub ($event) {
		my $left = $event->target;
		log_line('  OnHoverStopped %s', $left->file_name);
		$left->background_color($ROW_FILL);
		$left->remove_child($tooltip);
		return Clay::UI::Enum::Result->HANDLED;
	});
}

# OnScroll carries how far the position moved on each axis: delta_x for
# the folder strip, delta_y for the list. Momentum fires OnScroll for many
# frames; the script turns the log line off while it waits for the
# momentum to run out.
my $log_scrolls = 1;
for my $container ($list, $folders) {
	$container->on(OnScroll => sub ($event) {
		log_line('  OnScroll       %s moved by x=%g y=%g', $event->target->id, $event->delta_x, $event->delta_y)
			if $log_scrolls;
		return Clay::UI::Enum::Result->HANDLED;
	});
}

# ---- Helpers for the script ----

my $ui = Clay::UI->new(
	width        => 420,
	height       => 320,
	root         => $root,
	measure_text => sub ($text, $config, $userdata) {
		my $size = $config->{fontSize} || 16;
		return { width => length($text) * $size * 0.6, height => $size };
	},
);

sub describe_box ($widget) {
	my $box = $ui->bounding_box($widget) // return 'not laid out';
	return sprintf '%gx%g at (%g, %g)', @{$box}{qw(width height x y)};
}

sub show_scroll () {
	my $state = $ui->scroll_state($list);
	log_line('  scroll position y=%g (viewport %gx%g, content %gx%g)',
		$state->{position}{y},
		@{ $state->{viewport} }{qw(width height)},
		@{ $state->{content} }{qw(width height)});
	return;
}

sub show_tooltip () {
	my $row = $tooltip->parent;
	return log_line('  tooltip hidden') unless defined $row;
	log_line('  tooltip on %s: %s', $row->file_name, describe_box($tooltip));
	return;
}

# The pointer x inside the list; y is chosen per step.
my $LIST_X;

sub step ($title) {
	log_line("\n%s", $title);
	return;
}

# ---- Run the script ----

step('1. First frame');
$ui->render;
$LIST_X = $ui->bounding_box($list)->{x} + 50;
log_line('  list:  %s', describe_box($list));
log_line('  row 1: %s', describe_box($rows[0]));
show_scroll();

step('2. Hover the third row');
my $third_row_y = $ui->bounding_box($rows[2])->{y} + $ROW_HEIGHT / 2;
$ui->render(pointer_state => { x => $LIST_X, y => $third_row_y, down => 0 });
show_tooltip();

# Clay scrolls by 10 units per wheel step; negative y scrolls down.
step('3. Wheel: three steps down');
$ui->render(scroll_delta => { x => 0, y => -3 });
show_scroll();

# The pointer did not move, but the rows did: Clay hit-tests against the
# previous frame, so the next frame finds another row under the pointer.
step('4. Next frame: the row under the pointer changed');
$ui->render;
show_tooltip();

# Drag scrolling: press, move up while down, release. Clay keeps scrolling
# after the release (momentum): the faster the drag, the more. It measures
# the drag time by adding up delta_time, so this slow drag (a quarter
# second per frame) gives a short glide.
step('5. Drag 60 units up, release, two frames of momentum');
my %drag = (enable_drag_scrolling => 1, delta_time => 0.25);
for my $y (180, 150, 120) {
	$ui->render(%drag, pointer_state => { x => $LIST_X, y => $y, down => 1 });
}
$ui->render(%drag, pointer_state => { x => $LIST_X, y => 120, down => 0 });
show_scroll();
$ui->render(%drag) for 1 .. 2;
show_scroll();

# Clay shrinks the momentum by 5% per frame (not per second) and drops it
# below 0.1 units. The script lets it run out to show how long a glide
# lasts; a scroll_to would stop it at once.
step('6. Let the momentum run out');
my $frames = 0;
$log_scrolls = 0;
my $before;
do {
	$before = $ui->scroll_state($list)->{position}{y};
	$ui->render;
	$frames++;
} while ($ui->scroll_state($list)->{position}{y} != $before);
$log_scrolls = 1;
log_line('  stopped after %d frames', $frames);
show_scroll();

# scroll_to keeps the position within the content, so a huge offset lands
# on the last row. It moves the container between frames, so no OnScroll
# reports it; the next frame shows the new position.
step('7. scroll_to the very end, then back to y=-100');
my $at = $ui->scroll_to($list, { y => -1_000_000 });
log_line('  scroll_to returned y=%g', $at->{y});
$ui->render;
show_scroll();
$ui->scroll_to($list, { y => -100 });
$ui->render;
show_scroll();
$ui->render;
show_tooltip();

# The wheel scrolls the scroll container under the pointer, on the axes
# it scrolls: a scroll_delta x moves the folder strip sideways (negative
# x scrolls right, showing what lies beyond the right edge).
step('8. Pointer on the folder strip, wheel: four steps sideways');
my $strip_box = $ui->bounding_box($folders);
$ui->render(pointer_state => { x => $strip_box->{x} + 50, y => $strip_box->{y} + 12, down => 0 });
$ui->render(scroll_delta => { x => -4, y => 0 });
my $strip_state = $ui->scroll_state($folders);
log_line('  folder strip position x=%g (viewport width %g, content width %g)',
	$strip_state->{position}{x}, $strip_state->{viewport}{width}, $strip_state->{content}{width});

step('9. Move the pointer off the list, then onto the fifth visible row');
$ui->render(pointer_state => { x => 400, y => 10, down => 0 });
show_tooltip();
my $list_top = $ui->bounding_box($list)->{y};
$ui->render(pointer_state => { x => $LIST_X, y => $list_top + 4.5 * ($ROW_HEIGHT + 1), down => 0 });
my $commands = $ui->render;
show_tooltip();

# ---- Map render commands back to widgets ----
#
# Clay::UI puts a reference number into every command's userData;
# widget_for turns it back into the widget object.

step('10. Render commands of the last frame, by widget class');
my %count_by_class;
for my $command (@$commands) {
	my $widget = $ui->widget_for($command->{userData});
	# Clay gives SCISSOR_END commands no userData.
	my $class  = defined $widget ? ref $widget : '(no widget: scissor end)';
	$count_by_class{$class}++;
}
log_line('  %-26s %d', $_, $count_by_class{$_}) for sort keys %count_by_class;

# ---- SVG output ----
#
# Commands come in drawing order. A scroll container is drawn between a
# SCISSOR_START and a SCISSOR_END command; the renderer turns that into an
# SVG clip path so rows scrolled out of view are cut off.

sub xml_escape ($text) {
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	$text =~ s/"/&quot;/g;
	return $text;
}

# SVG 1.1 has no rgba(): the colour goes into fill as rgb() and the alpha
# into fill-opacity.
sub fill_attributes ($color) {
	my $fill = sprintf 'fill="rgb(%d,%d,%d)"', @{$color}{qw(r g b)};
	return $fill if $color->{a} >= 255;
	return sprintf '%s fill-opacity="%.3f"', $fill, $color->{a} / 255;
}

sub svg_rectangle ($command) {
	my ($box, $data) = @{$command}{qw(boundingBox renderData)};
	my $radius = $data->{cornerRadius}{topLeft} // 0;
	return sprintf qq{<rect x="%g" y="%g" width="%g" height="%g" rx="%g" %s/>\n},
		@{$box}{qw(x y width height)}, $radius, fill_attributes($data->{backgroundColor});
}

sub svg_text ($command) {
	my ($box, $data) = @{$command}{qw(boundingBox renderData)};
	return sprintf qq{<text x="%g" y="%g" font-size="%g" font-family="monospace" %s>%s</text>\n},
		$box->{x}, $box->{y} + $box->{height} - 3, $data->{fontSize},
		fill_attributes($data->{textColor}), xml_escape($data->{stringContents});
}

sub render_svg ($commands, $width, $height) {
	my $svg = qq{<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height">\n};
	my $clip_count = 0;
	for my $command (@$commands) {
		my $type = $command->{commandType};
		if ($type == CLAY_RENDER_COMMAND_TYPE_RECTANGLE) {
			$svg .= svg_rectangle($command);
		} elsif ($type == CLAY_RENDER_COMMAND_TYPE_TEXT) {
			$svg .= svg_text($command);
		} elsif ($type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START) {
			my $id = 'clip' . ++$clip_count;
			$svg .= sprintf qq{<clipPath id="%s"><rect x="%g" y="%g" width="%g" height="%g"/></clipPath>\n<g clip-path="url(#%s)">\n},
				$id, @{ $command->{boundingBox} }{qw(x y width height)}, $id;
		} elsif ($type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END) {
			$svg .= "</g>\n";
		}
	}
	return $svg . "</svg>\n";
}

my $svg = render_svg($commands, $ui->width, $ui->height);
if (defined $OUTPUT) {
	open my $fh, '>', $OUTPUT or die "cannot write '$OUTPUT': $!\n";
	print {$fh} $svg;
	close $fh or die "cannot write '$OUTPUT': $!\n";
	log_line("\nWrote %s", $OUTPUT);
} else {
	print $svg;
}
