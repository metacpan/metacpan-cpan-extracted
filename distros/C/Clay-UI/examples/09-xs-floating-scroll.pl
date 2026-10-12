#!/usr/bin/env perl

# 09-xs-floating-scroll.pl - Scrolling, floating elements and pointer input.
#
# Builds a small window with Clay::XS: a scrollable list, a "Menu" button
# that opens a dropdown and a help icon that shows a tooltip. Then it feeds
# the window a scripted sequence of pointer moves, a click and mouse-wheel
# input. Each frame prints
# what Clay reports; the last frame's render commands are listed as a table.
# Nothing is drawn: the point is the order of the input calls and what each
# query returns.
#
# Shows:
#   - a scroll container: clip with the scroll offset fed back as childOffset
#   - mouse-wheel scrolling and jumping to a scroll position from code
#   - a dropdown floating below its parent, and a tooltip attached by id
#   - z order, attach points, offsets and pointer capture of floating elements
#   - hit testing: which elements are under the pointer, hover callbacks
#   - reading an element's bounding box and a scroll container's state
#
# Features: Clay_SetPointerState, Clay_GetPointerState, Clay_PointerOver, Clay_GetPointerOverIds, Clay_Hovered, Clay_OnHover, Clay_UpdateScrollContainers, Clay_GetScrollOffset, Clay_GetScrollContainerData, set_scroll_position, Clay_GetElementData, clip, childOffset, floating, attachTo, CLAY_ATTACH_TO_PARENT, CLAY_ATTACH_TO_ELEMENT_WITH_ID, parentId, attachPoints, offset, zIndex, pointerCaptureMode, CLAY_POINTER_CAPTURE_MODE_CAPTURE, CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH, CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/09-xs-floating-scroll.pl

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

my ($WIDTH, $HEIGHT) = (480, 320);
my $FRAME_TIME       = 0.016;    # seconds per simulated frame
my $ROW_COUNT        = 24;
my @MENU_ENTRIES     = qw(Open Save Quit);

my $WHITE      = [255, 255, 255, 255];
my $DARK_TEXT  = [ 30,  30,  40, 255];
my $ROW_COLOR  = [235, 238, 245, 255];
my $ROW_HOVER  = [255, 214, 140, 255];
my $ACCENT     = [ 50, 100, 200, 255];
my $MENU_COLOR = [ 60,  60,  70, 255];

# ---------------------------------------------------------------------------
# Readable names for ids and constants
# ---------------------------------------------------------------------------

# Render commands and hover callbacks carry numeric element ids. Every
# element this script opens goes through open_element, which remembers a
# readable label for its id.
my %label_of_id;

sub open_element ($name, $index = undef) {
	my $id = defined $index ? Clay_GetElementIdWithIndex($name, $index) : Clay_GetElementId($name);
	$label_of_id{ $id->{id} } = defined $index ? "$name\[$index]" : $name;
	Clay__OpenElementWithId($id);
	return $id;
}

# Clay's own root element has a string id; text elements get generated
# ids without one.
sub label_of ($element_id) {
	return $label_of_id{ $element_id->{id} } // $element_id->{stringId} // '(text)';
}

my %POINTER_STATE_NAME = (
	CLAY_POINTER_DATA_PRESSED_THIS_FRAME()  => 'PRESSED_THIS_FRAME',
	CLAY_POINTER_DATA_PRESSED()             => 'PRESSED',
	CLAY_POINTER_DATA_RELEASED_THIS_FRAME() => 'RELEASED_THIS_FRAME',
	CLAY_POINTER_DATA_RELEASED()            => 'RELEASED',
);

my %COMMAND_TYPE_NAME = (
	CLAY_RENDER_COMMAND_TYPE_RECTANGLE()     => 'RECTANGLE',
	CLAY_RENDER_COMMAND_TYPE_BORDER()        => 'BORDER',
	CLAY_RENDER_COMMAND_TYPE_TEXT()          => 'TEXT',
	CLAY_RENDER_COMMAND_TYPE_IMAGE()         => 'IMAGE',
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_START() => 'SCISSOR_START',
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_END()   => 'SCISSOR_END',
	CLAY_RENDER_COMMAND_TYPE_CUSTOM()        => 'CUSTOM',
);

# ---------------------------------------------------------------------------
# Context setup
# ---------------------------------------------------------------------------

my $ctx = Clay_Initialize(
	Clay_MinMemorySize(),
	{ width => $WIDTH, height => $HEIGHT },
	sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);

# Monospace approximation; good enough to size labels.
Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
	my $font_size = $config->{fontSize} || 16;
	return { width => length($text) * $font_size * 0.55, height => $font_size };
});

# ---------------------------------------------------------------------------
# Application state, changed by input between frames
# ---------------------------------------------------------------------------

my %ui = (
	menu_open    => 0,
	show_tooltip => 0,
);

# Hover callbacks only collect what happened; the frame log prints it.
my @hover_events;

sub on_row_hover ($element_id, $pointer, $row_index) {
	push @hover_events, sprintf 'hover callback: %s, userdata %d, pointer state %s',
		label_of($element_id), $row_index, $POINTER_STATE_NAME{ $pointer->{state} };
}

# ---------------------------------------------------------------------------
# The layout
# ---------------------------------------------------------------------------

sub text ($string, $color = $DARK_TEXT) {
	Clay__OpenTextElement($string, { fontSize => 14, textColor => $color });
}

sub declare_dropdown () {
	open_element('dropdown');
	Clay__ConfigureOpenElement({
		layout => {
			layoutDirection => CLAY_TOP_TO_BOTTOM,
			padding         => padding_all(4),
			childGap        => 2,
		},
		backgroundColor => $MENU_COLOR,
		cornerRadius    => corner_radius_all(4),
		floating        => {
			# Float relative to the element this one is declared in (the
			# button): the dropdown's top-left corner sits on the button's
			# bottom-left corner, 4 pixels lower.
			attachTo     => CLAY_ATTACH_TO_PARENT,
			attachPoints => {
				element => CLAY_ATTACH_POINT_LEFT_TOP,
				parent  => CLAY_ATTACH_POINT_LEFT_BOTTOM,
			},
			offset => { x => 0, y => 4 },
			zIndex => 10,
			# CAPTURE: while the pointer is over the dropdown, elements
			# underneath (the list) are not reported as hovered.
			pointerCaptureMode => CLAY_POINTER_CAPTURE_MODE_CAPTURE,
		},
	});
		for my $index (0 .. $#MENU_ENTRIES) {
			open_element('menu-item', $index);
			Clay__ConfigureOpenElement({
				layout => {
					sizing  => { width => sizing_fixed(140), height => sizing_fixed(26) },
					padding => { left => 8, top => 6 },
				},
				backgroundColor => Clay_Hovered() ? $ACCENT : $MENU_COLOR,
			});
				text($MENU_ENTRIES[$index], $WHITE);
			Clay__CloseElement();
		}
	Clay__CloseElement();
}

sub declare_toolbar () {
	open_element('toolbar');
	Clay__ConfigureOpenElement({
		layout => {
			sizing         => { width => sizing_grow(), height => sizing_fixed(36) },
			padding        => padding_all(4),
			childGap       => 12,
			childAlignment => { y => CLAY_ALIGN_Y_CENTER },
		},
		backgroundColor => $WHITE,
	});
		open_element('menu-button');
		Clay__ConfigureOpenElement({
			layout => {
				sizing         => { width => sizing_fixed(80), height => sizing_fixed(28) },
				childAlignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
			},
			backgroundColor => $ACCENT,
			cornerRadius    => corner_radius_all(4),
		});
			text('Menu', $WHITE);
			# A floating child is declared inside its parent but takes no
			# space there; see Clay::XS, floating.
			declare_dropdown() if $ui{menu_open};
		Clay__CloseElement();
		text('Floating and scrolling demo');
	Clay__CloseElement();
}

sub declare_list () {
	open_element('list');
	Clay__ConfigureOpenElement({
		layout => {
			sizing          => { width => sizing_fixed(220), height => sizing_grow() },
			layoutDirection => CLAY_TOP_TO_BOTTOM,
			padding         => padding_all(4),
			childGap        => 2,
		},
		backgroundColor => $WHITE,
		# clip makes this a scroll container. Clay keeps the scroll
		# position; feeding it back as childOffset moves the children.
		# Clay_GetScrollOffset answers for the element just opened.
		clip => { vertical => 1, childOffset => Clay_GetScrollOffset() },
	});
		for my $index (0 .. $ROW_COUNT - 1) {
			open_element('row', $index);
			# Clay forgets hover callbacks when an element is declared
			# again, so they are registered every frame.
			Clay_OnHover(\&on_row_hover, $index);
			Clay__ConfigureOpenElement({
				layout => {
					sizing  => { width => sizing_grow(), height => sizing_fixed(26) },
					padding => { left => 8, top => 6 },
				},
				# Clay_Hovered asks about the open element, using the
				# pointer position of the last Clay_SetPointerState.
				backgroundColor => Clay_Hovered() ? $ROW_HOVER : $ROW_COLOR,
			});
				text("Item $index");
			Clay__CloseElement();
		}
	Clay__CloseElement();
}

sub declare_side_panel () {
	open_element('side-panel');
	Clay__ConfigureOpenElement({
		layout => {
			sizing          => { width => sizing_grow(), height => sizing_grow() },
			layoutDirection => CLAY_TOP_TO_BOTTOM,
			padding         => padding_all(8),
			childGap        => 8,
		},
		backgroundColor => $WHITE,
	});
		open_element('help-icon');
		Clay__ConfigureOpenElement({
			layout => {
				sizing         => { width => sizing_fixed(28), height => sizing_fixed(28) },
				childAlignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
			},
			backgroundColor => $ACCENT,
			cornerRadius    => corner_radius_all(14),
		});
			text('?', $WHITE);
		Clay__CloseElement();
		text('Hover the icon');
	Clay__CloseElement();
}

sub declare_tooltip () {
	open_element('tooltip');
	Clay__ConfigureOpenElement({
		layout          => { padding => padding_all(6) },
		backgroundColor => [20, 20, 20, 230],
		cornerRadius    => corner_radius_all(3),
		floating        => {
			# Declared at the end of the root, but attached to the help
			# icon by id: its left-center point sits 8 pixels right of the
			# icon's right-center point.
			attachTo     => CLAY_ATTACH_TO_ELEMENT_WITH_ID,
			parentId     => Clay_GetElementId('help-icon'),
			attachPoints => {
				element => CLAY_ATTACH_POINT_LEFT_CENTER,
				parent  => CLAY_ATTACH_POINT_RIGHT_CENTER,
			},
			offset => { x => 8, y => 0 },
			zIndex => 20,
			# PASSTHROUGH: the pointer still reaches the elements below,
			# so hovering the tooltip does not "unhover" the icon.
			pointerCaptureMode => CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
		},
	});
		text('Opens the manual', $WHITE);
	Clay__CloseElement();
}

sub declare_window () {
	open_element('root');
	Clay__ConfigureOpenElement({
		layout => {
			sizing          => { width => sizing_grow(), height => sizing_grow() },
			layoutDirection => CLAY_TOP_TO_BOTTOM,
			padding         => padding_all(12),
			childGap        => 8,
		},
		backgroundColor => [210, 214, 222, 255],
	});
		declare_toolbar();
		open_element('body');
		Clay__ConfigureOpenElement({
			layout => {
				sizing   => { width => sizing_grow(), height => sizing_grow() },
				childGap => 12,
			},
		});
			declare_list();
			declare_side_panel();
		Clay__CloseElement();
		declare_tooltip() if $ui{show_tooltip};
	Clay__CloseElement();
}

# ---------------------------------------------------------------------------
# Queries used by the input script and the log
# ---------------------------------------------------------------------------

# Clay_GetElementData returns the bounding box from the last completed frame.
sub center_of ($name, $index = undef) {
	my $id   = defined $index ? Clay_GetElementIdWithIndex($name, $index) : Clay_GetElementId($name);
	my $data = Clay_GetElementData($id);
	die "center_of: element '$name' was not in the last frame\n" unless $data->{found};
	my $box = $data->{boundingBox};
	return { x => $box->{x} + $box->{width} / 2, y => $box->{y} + $box->{height} / 2 };
}

sub describe_box ($name) {
	my $data = Clay_GetElementData( Clay_GetElementId($name) );
	return "$name: not in the last frame" unless $data->{found};
	my $box = $data->{boundingBox};
	return sprintf '%s: x=%g y=%g w=%g h=%g', $name, @$box{qw(x y width height)};
}

sub describe_pointer_over_ids () {
	my @labels = map { label_of($_) } @{ Clay_GetPointerOverIds() };
	return @labels ? join(', ', @labels) : '(nothing)';
}

sub describe_list_scroll () {
	my $data = Clay_GetScrollContainerData( Clay_GetElementId('list') );
	return 'list is not a scroll container yet' unless $data->{found};
	return sprintf 'list scrollPosition.y=%g (visible %gpx of %gpx content)',
		$data->{scrollPosition}{y},
		$data->{scrollContainerDimensions}{height},
		$data->{contentDimensions}{height};
}

# ---------------------------------------------------------------------------
# Input script: one entry per frame
# ---------------------------------------------------------------------------

# pointer is a code ref, so positions come from the previous frame's
# layout instead of being hard-coded.
#
# The first frame parks the pointer outside the window: nothing is
# hovered until the script moves it.
my @input_script = (
	{ title => 'first frame, pointer outside the window',
	  pointer => sub { { x => -1, y => -1 } } },
	{ title => 'pointer moves over row 2',
	  pointer => sub { center_of('row', 2) } },
	{ title => 'mouse wheel: 3 notches down over the list',
	  pointer => sub { center_of('row', 2) }, wheel => -3 },
	{ title => 'pointer moves over the help icon',
	  pointer => sub { center_of('help-icon') } },
	{ title => 'button pressed over Menu',
	  pointer => sub { center_of('menu-button') }, down => 1 },
	{ title => 'button released',
	  pointer => sub { center_of('menu-button') } },
	{ title => 'pointer moves onto the dropdown, above the list',
	  pointer => sub { center_of('menu-item', 1) } },
	{ title => 'mouse wheel over the dropdown',
	  pointer => sub { center_of('menu-item', 1) }, wheel => -3 },
	{ title => 'code jumps the list to its end with set_scroll_position',
	  pointer => sub { center_of('help-icon') }, scroll_list_to_end => 1 },
);

# ---------------------------------------------------------------------------
# Frame loop
# ---------------------------------------------------------------------------

sub apply_input ($step) {
	my @log;
	if (my $position_of = $step->{pointer}) {
		my $position = $position_of->();
		@hover_events = ();
		# Hit-tests against the last completed frame and runs the hover
		# callbacks registered while it was declared. Those see the pointer
		# state from before this call (see Clay::XS, CALLBACKS), so clicks
		# are read from Clay_GetPointerState afterwards.
		Clay_SetPointerState($position, $step->{down} // 0);
		push @log, sprintf 'pointer at (%g, %g), state %s',
			$position->{x}, $position->{y}, $POINTER_STATE_NAME{ Clay_GetPointerState()->{state} };
		push @log, @hover_events;
		push @log, 'pointer over: ' . describe_pointer_over_ids();
	}

	# Called every frame: it also runs scroll momentum. The wheel delta is
	# in notches; Clay scrolls 10 pixels per notch, and only the innermost
	# scroll container under the pointer moves.
	Clay_UpdateScrollContainers(0, { x => 0, y => $step->{wheel} // 0 }, $FRAME_TIME);

	if ($step->{scroll_list_to_end}) {
		my $data   = Clay_GetScrollContainerData( Clay_GetElementId('list') );
		my $bottom = $data->{scrollContainerDimensions}{height} - $data->{contentDimensions}{height};
		set_scroll_position(Clay_GetElementId('list'), { x => 0, y => $bottom });
		push @log, "set_scroll_position(list, y => $bottom)";
	}

	my $clicked_menu = Clay_GetPointerState()->{state} == CLAY_POINTER_DATA_PRESSED_THIS_FRAME
		&& Clay_PointerOver( Clay_GetElementId('menu-button') );
	if ($clicked_menu) {
		$ui{menu_open} = !$ui{menu_open};
		push @log, 'Menu clicked: dropdown ' . ($ui{menu_open} ? 'opens' : 'closes');
	}

	my $was_showing = $ui{show_tooltip};
	$ui{show_tooltip} = Clay_PointerOver( Clay_GetElementId('help-icon') ) ? 1 : 0;
	push @log, 'tooltip ' . ($ui{show_tooltip} ? 'shown' : 'hidden') if $was_showing != $ui{show_tooltip};
	return @log;
}

sub run_frame ($step) {
	my @log = apply_input($step);
	Clay_BeginLayout();
	declare_window();
	my $commands = Clay_EndLayout($FRAME_TIME);
	push @log, describe_list_scroll();
	return ($commands, @log);
}

my $last_commands;
for my $frame_number (1 .. @input_script) {
	my $step = $input_script[ $frame_number - 1 ];
	my ($commands, @log) = run_frame($step);
	say "Frame $frame_number: $step->{title}";
	say "    $_" for @log;
	$last_commands = $commands;
}

say '';
say 'Bounding boxes after the last frame (Clay_GetElementData):';
say "    $_" for map { describe_box($_) } qw(menu-button dropdown list help-icon tooltip);

# ---------------------------------------------------------------------------
# Render commands of the last frame
# ---------------------------------------------------------------------------

# Clay culls elements outside the window, not outside the list: row 13
# lies above the list but inside the window, so it is still listed.
# SCISSOR_START / SCISSOR_END bracket the list's children, and a renderer
# clips everything between them to the scissor box (the list's bounds).
# Clay already emits the commands in drawing order, the floating dropdown
# (zIndex 10) and tooltip (20) last, so a renderer draws them in array
# order; every command of a floating element carries its zIndex, so
# sorting by zIndex works as well.
sub command_detail ($cmd) {
	my $data = $cmd->{renderData};
	my $type = $cmd->{commandType};
	return qq{"$data->{stringContents}"} if $type == CLAY_RENDER_COMMAND_TYPE_TEXT;
	return "vertical=$data->{vertical}"   if $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START;
	return ''                             if $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END;
	my $color = $data->{backgroundColor} // $data->{color};
	return $color ? sprintf('rgba(%d,%d,%d,%d)', @$color{qw(r g b a)}) : '';
}

sub command_element ($cmd) {
	return '(text)' if $cmd->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT;
	return $label_of_id{ $cmd->{id} } // '-';    # SCISSOR_END has an id of its own
}

say '';
say 'Render commands of the last frame:';
printf "    %-3s %-13s %3s %6s %6s %6s %6s  %-14s %s\n", '#', 'type', 'z', 'x', 'y', 'w', 'h', 'element', 'detail';
my $number = 0;
for my $cmd (@$last_commands) {
	my $box = $cmd->{boundingBox};
	printf "    %-3d %-13s %3d %6g %6g %6g %6g  %-14s %s\n",
		$number++, $COMMAND_TYPE_NAME{ $cmd->{commandType} }, $cmd->{zIndex},
		@$box{qw(x y width height)}, command_element($cmd), command_detail($cmd);
}
