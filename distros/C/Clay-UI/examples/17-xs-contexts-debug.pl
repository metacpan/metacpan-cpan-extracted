#!/usr/bin/env perl

# 17-xs-contexts-debug.pl - Contexts, capacity, culling, debug view and ids.
#
# A tour of the Clay::XS settings most programs touch once: sizing a
# context's memory, running two contexts side by side, resizing the
# layout, culling, Clay's built-in debug view, scrolling done by the host
# application, local element ids, a modal attached to the root, newline
# wrapping and telling Clay's error types apart. Every section lays out a
# small frame and prints what changed. Nothing is drawn.
#
# Shows:
#   - element and measure-cache counts, and the memory they need
#   - two independent contexts and switching between them
#   - changing the layout size between frames
#   - culling on and off, and the extra commands of the debug view
#   - scroll positions supplied by the application instead of Clay
#   - local ids (the same name inside different parents) and the id of
#     an element opened without one
#   - a modal floating over the whole layout, enlarged with expand, and
#     a floating badge clipped (or not) like the element it is attached to
#   - text that breaks only at newlines
#   - an error handler that tells a duplicate id apart from other errors,
#     and sizing groups nested in a cycle
#
# Features: Clay_Initialize, Clay_MinMemorySize, Clay_SetMaxElementCount, Clay_SetMaxMeasureTextCacheWordCount, Clay_GetMaxElementCount, Clay_GetMaxMeasureTextCacheWordCount, Clay_ResetMeasureTextCache, Clay_SetCurrentContext, Clay_GetCurrentContext, Clay_SetLayoutDimensions, Clay_GetLayoutDimensions, Clay_SetCullingEnabled, Clay_SetDebugModeEnabled, Clay_IsDebugModeEnabled, Clay_SetExternalScrollHandlingEnabled, Clay_SetQueryScrollOffsetFunction, Clay_GetScrollContainerData, Clay_GetElementData, Clay_GetOpenElementId, Clay__OpenElement, Clay__HashString, Clay__HashStringWithOffset, floating, CLAY_ATTACH_TO_ROOT, CLAY_ATTACH_TO_PARENT, expand, clipTo, CLAY_CLIP_TO_ATTACHED_PARENT, CLAY_CLIP_TO_NONE, wrapMode, CLAY_TEXT_WRAP_WORDS, CLAY_TEXT_WRAP_NEWLINES, CLAY_TEXT_WRAP_NONE, sizingGroup, errorType, errorText, CLAY_ERROR_TYPE_DUPLICATE_ID, CLAY_ERROR_TYPE_SIZING_GROUP_CYCLE
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/17-xs-contexts-debug.pl

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

my %COMMAND_TYPE_NAME = (
	CLAY_RENDER_COMMAND_TYPE_RECTANGLE()           => 'RECTANGLE',
	CLAY_RENDER_COMMAND_TYPE_BORDER()              => 'BORDER',
	CLAY_RENDER_COMMAND_TYPE_TEXT()                => 'TEXT',
	CLAY_RENDER_COMMAND_TYPE_IMAGE()               => 'IMAGE',
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_START()       => 'SCISSOR_START',
	CLAY_RENDER_COMMAND_TYPE_SCISSOR_END()         => 'SCISSOR_END',
	CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START() => 'OVERLAY_COLOR_START',
	CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END()   => 'OVERLAY_COLOR_END',
	CLAY_RENDER_COMMAND_TYPE_CUSTOM()              => 'CUSTOM',
);

# errorType is a number; this maps every CLAY_ERROR_TYPE_* constant to
# its name without the prefix.
my %ERROR_TYPE_NAME = map { (Clay::XS->can($_)->() => s/^CLAY_ERROR_TYPE_//r) }
	grep { /^CLAY_ERROR_TYPE_/ } @Clay::XS::EXPORT_OK;

sub heading ($title) {
	say "\n$title";
	return;
}

# One frame in the current context: $declare opens and closes elements.
sub lay_out ($declare) {
	Clay_BeginLayout();
	$declare->();
	return Clay_EndLayout(0);
}

sub count_by_type ($commands) {
	my %count;
	$count{ $COMMAND_TYPE_NAME{ $_->{commandType} } }++ for @$commands;
	return join ', ', map { "$_ $count{$_}" } sort keys %count;
}

sub text ($string, %config) {
	Clay__OpenTextElement($string, { fontSize => 10, textColor => [0, 0, 0, 255], %config });
	return;
}

# A box with an id, fixed or growing size and optional extra declaration keys.
sub box ($name, $width, $height, $children = sub { }, %extra) {
	Clay__OpenElementWithId(Clay_GetElementId($name));
	Clay__ConfigureOpenElement({
		layout          => { sizing => { width => $width, height => $height }, %{ delete $extra{layout} // {} } },
		backgroundColor => [200, 200, 210, 255],
		%extra,
	});
	$children->();
	Clay__CloseElement();
	return;
}

sub describe_box ($name) {
	my $data = Clay_GetElementData(Clay_GetElementId($name));
	return "$name: not in the last frame of this context" unless $data->{found};
	return sprintf '%s: %gx%g at (%g, %g)', $name, @{ $data->{boundingBox} }{qw(width height x y)};
}

# Every character is 6 units wide; each context needs its own function.
sub measure_text ($string, $config, $userdata) {
	return { width => 6 * length $string, height => $config->{fontSize} };
}

# Collects Clay's error reports for the section that provokes one.
my @clay_errors;

sub collect_error ($error, $userdata) {
	push @clay_errors, $error;
	return;
}

# ---------------------------------------------------------------------------
# 1. Counts and memory
# ---------------------------------------------------------------------------
#
# A context gets a fixed amount of memory when it is created. The
# element count bounds the elements, text lines and render commands of a
# frame; the word count bounds Clay's text measurement cache. Without a
# current context the setters change Clay's process-wide defaults, which
# Clay_MinMemorySize and Clay_Initialize read. See Clay::XS,
# Clay_SetMaxElementCount.

heading('1. Counts and memory');
printf "  default counts (8192 elements, 16384 words) need %d bytes\n", Clay_MinMemorySize();
Clay_SetMaxElementCount(256);
Clay_SetMaxMeasureTextCacheWordCount(1024);
printf "  256 elements, 1024 words need %d bytes\n", Clay_MinMemorySize();

my $main = Clay_Initialize(Clay_MinMemorySize(), { width => 300, height => 200 }, \&collect_error);
Clay_SetMeasureTextFunction(\&measure_text);
printf "  main context: Clay_GetMaxElementCount %d, Clay_GetMaxMeasureTextCacheWordCount %d\n",
	Clay_GetMaxElementCount(), Clay_GetMaxMeasureTextCacheWordCount();

# A live context cannot grow. With a context current, the setter changes
# the counts the next Clay_Initialize uses, and the live context refuses
# to work until it gets its own counts back.
Clay_SetMaxElementCount(512);
my $refusal = eval { Clay_GetLayoutDimensions(); 1 } ? 'no error' : $@ =~ s/ at \S+ line \d+\.\n\z//r;
printf "  after Clay_SetMaxElementCount(512) the main context croaks:\n    %s\n", $refusal;
Clay_SetMaxElementCount(256);
printf "  back at 256 it works again: layout is %gx%g\n", @{ Clay_GetLayoutDimensions() }{qw(width height)};

# Clay caches the measured width of every word. After a font change the
# cache would answer with old widths; Clay_ResetMeasureTextCache empties
# it, so the next frame measures every word again.
my $measure_calls = 0;
Clay_SetMeasureTextFunction(sub ($string, $config, $userdata) { $measure_calls++; measure_text($string, $config, $userdata) });
my @calls_per_frame;
for my $reset_first (0, 0, 1) {
	Clay_ResetMeasureTextCache() if $reset_first;
	$measure_calls = 0;
	lay_out(sub { text('cached words') });
	push @calls_per_frame, $measure_calls;
}
printf "  measure calls per frame: %d, then %d (cached), then %d after Clay_ResetMeasureTextCache\n", @calls_per_frame;
Clay_SetMeasureTextFunction(\&measure_text);

# ---------------------------------------------------------------------------
# 2. Two contexts
# ---------------------------------------------------------------------------
#
# Each context is an independent Clay instance with its own elements,
# scroll positions, callbacks and settings. Clay_Initialize makes the new
# context current (sized for the current context's counts); every other
# function works on the current one. See Clay::XS, CONTEXTS.

heading('2. Two contexts');
my $preview = Clay_Initialize(Clay_MinMemorySize(), { width => 120, height => 80 }, \&collect_error);
Clay_SetMeasureTextFunction(\&measure_text);
printf "  Clay_GetCurrentContext is the preview context: %s\n", Clay_GetCurrentContext() == $preview ? 'yes' : 'no';
lay_out(sub { box('thumbnail', sizing_grow(), sizing_grow()) });

Clay_SetCurrentContext($main);
lay_out(sub {
	box('page', sizing_grow(), sizing_grow(), sub {
		box('sidebar', sizing_fixed(80), sizing_grow());
	});
});
say '  in the main context:';
say "    $_" for describe_box('sidebar'), describe_box('thumbnail');

Clay_SetCurrentContext($preview);
say '  in the preview context:';
say "    $_" for describe_box('sidebar'), describe_box('thumbnail');
Clay_SetCurrentContext($main);

# ---------------------------------------------------------------------------
# 3. Layout dimensions
# ---------------------------------------------------------------------------
#
# The root element takes its size from the layout dimensions when a frame
# begins, so a window resize is one call before the next frame.

heading('3. Layout dimensions');
my $declare_page = sub {
	box('page', sizing_grow(), sizing_grow(), sub {
		box('sidebar', sizing_fixed(80), sizing_grow());
		box('content', sizing_grow(), sizing_grow());
	});
};
lay_out($declare_page);
printf "  Clay_GetLayoutDimensions: %gx%g, %s\n", @{ Clay_GetLayoutDimensions() }{qw(width height)}, describe_box('content');
Clay_SetLayoutDimensions({ width => 500, height => 120 });
lay_out($declare_page);
printf "  after Clay_SetLayoutDimensions: %gx%g, %s\n", @{ Clay_GetLayoutDimensions() }{qw(width height)}, describe_box('content');
Clay_SetLayoutDimensions([300, 200]);

# ---------------------------------------------------------------------------
# 4. Culling
# ---------------------------------------------------------------------------
#
# With culling on (the default) Clay emits no commands for elements that
# lie entirely outside the layout. Ten 40 unit rows in a 200 unit high
# layout: culling keeps the column and the rows that reach into the
# layout (a row touching the bottom edge counts), and drops the rest.

heading('4. Culling');
my $declare_rows = sub {
	box('column', sizing_grow(), sizing_fit(), sub {
		box("row-$_", sizing_grow(), sizing_fixed(40)) for 1 .. 10;
	}, layout => { layoutDirection => CLAY_TOP_TO_BOTTOM });
};
printf "  culling on:  %s\n", count_by_type(lay_out($declare_rows));
Clay_SetCullingEnabled(0);
printf "  culling off: %s\n", count_by_type(lay_out($declare_rows));
Clay_SetCullingEnabled(1);

# ---------------------------------------------------------------------------
# 5. The debug view
# ---------------------------------------------------------------------------
#
# Clay's debug view is a panel on the right that lists the element tree.
# It is made of ordinary render commands, so a renderer draws it like the
# rest; the root element gets narrower by the panel's width. Its text
# uses fontId 0 and the measure function.

heading('5. The debug view');
my $plain = lay_out($declare_page);
printf "  off: %d commands (%s), %s\n", scalar @$plain, count_by_type($plain), describe_box('page');
Clay_SetDebugModeEnabled(1);
printf "  Clay_IsDebugModeEnabled: %s\n", Clay_IsDebugModeEnabled() ? 'true' : 'false';
my $debug = lay_out($declare_page);
printf "  on:  %d commands (%s), %s\n", scalar @$debug, count_by_type($debug), describe_box('page');
my @panel_texts = map { $_->{renderData}{stringContents} }
	grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$debug;
printf "  first texts of the panel: %s\n", join ', ', map { qq{"$_"} } @panel_texts[ 0 .. 3 ];
Clay_SetDebugModeEnabled(0);

# ---------------------------------------------------------------------------
# 6. Scrolling handled by the application
# ---------------------------------------------------------------------------
#
# Some hosts scroll content themselves (native scroll views, for example).
# With external scroll handling on, Clay asks the query-scroll function
# for every scroll container's position while the container is
# configured, and leaves the children where they are: moving them by the
# position is the renderer's job. See Clay::XS,
# Clay_SetExternalScrollHandlingEnabled.

heading('6. Scrolling handled by the application');
my %host_scroll_position = (Clay_GetElementId('list')->{id} => { x => 0, y => -30 });
my @asked_for;
Clay_SetQueryScrollOffsetFunction(sub ($element_id, $userdata) {
	push @asked_for, $element_id;
	return $host_scroll_position{$element_id} // { x => 0, y => 0 };
});
# Clay_GetScrollOffset answers for the open element, so it is read
# after 'list' is opened (see Clay::XS, Clay_GetScrollOffset).
my $frame_with_list = sub {
	lay_out(sub {
		Clay__OpenElementWithId(Clay_GetElementId('list'));
		Clay__ConfigureOpenElement({
			layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(60) }, layoutDirection => CLAY_TOP_TO_BOTTOM },
			clip   => { vertical => 1, childOffset => Clay_GetScrollOffset() },
		});
		box("item-$_", sizing_grow(), sizing_fixed(20)) for 1 .. 6;
		Clay__CloseElement();
	});
};
Clay_SetExternalScrollHandlingEnabled(1);
$frame_with_list->();
my $scroll = Clay_GetScrollContainerData(Clay_GetElementId('list'));
printf "  query function called for 'list': %s\n", (grep { $_ == Clay_GetElementId('list')->{id} } @asked_for) ? 'yes' : 'no';
printf "  Clay_GetScrollContainerData: scrollPosition.y %g\n", $scroll->{scrollPosition}{y};
printf "  %s (not moved: the renderer applies the offset)\n", describe_box('item-1');
Clay_SetExternalScrollHandlingEnabled(0);
Clay_SetQueryScrollOffsetFunction(undef);

# ---------------------------------------------------------------------------
# 7. Local ids and anonymous elements
# ---------------------------------------------------------------------------
#
# Clay_GetElementId('title') is the same id wherever it is used, so two
# cards cannot both have a child called 'title'. A local id hashes the
# name with the parent's id as seed (C's CLAY_ID_LOCAL): the same name
# gives a different id in each parent. Clay_GetOpenElementId returns the
# id of the open element, also for one opened without an id.

heading('7. Local ids and anonymous elements');
my %local_title_id;
my $anonymous_id;
lay_out(sub {
	box('cards', sizing_grow(), sizing_fit(), sub {
		for my $card (qw(card-a card-b)) {
			box($card, sizing_grow(), sizing_fit(), sub {
				my $title_id = Clay__HashString('title', Clay_GetOpenElementId());
				$local_title_id{$card} = $title_id->{id};
				Clay__OpenElementWithId($title_id);
				Clay__ConfigureOpenElement({ layout => { padding => padding_all(2) } });
				text("Title of $card");
				Clay__CloseElement();
				# Indexed local ids: C's CLAY_IDI_LOCAL.
				for my $index (0 .. 1) {
					Clay__OpenElementWithId(Clay__HashStringWithOffset('tag', $index, Clay_GetOpenElementId()));
					Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } } });
					Clay__CloseElement();
				}
			}, layout => { layoutDirection => CLAY_TOP_TO_BOTTOM });
		}
		Clay__OpenElement();
		$anonymous_id = Clay_GetOpenElementId();
		Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed(20) } } });
		Clay__CloseElement();
	});
});
printf "  'title' in card-a: id %d, in card-b: id %d, Clay errors: %d\n", @local_title_id{qw(card-a card-b)}, scalar @clay_errors;
for my $card (qw(card-a card-b)) {
	my $seed = Clay_GetElementId($card)->{id};
	my $tag  = Clay_GetElementData(Clay__HashStringWithOffset('tag', 1, $seed));
	printf "  second tag of %s found again after the frame at x=%g\n", $card, $tag->{boundingBox}{x};
}
printf "  anonymous element: Clay_GetOpenElementId %d, found by that id: %s\n",
	$anonymous_id, Clay_GetElementData({ id => $anonymous_id })->{found} ? 'yes' : 'no';

# ---------------------------------------------------------------------------
# 8. A modal over the root, and clipped floating elements
# ---------------------------------------------------------------------------
#
# CLAY_ATTACH_TO_ROOT positions a floating element against the whole
# layout, wherever it is declared: here a modal centred on the root.
# expand grows the floating element's own box on every side without
# moving its children, for a margin that is not padding.
#
# clipTo decides whether a floating element is clipped like the element
# it is attached to. A badge attached to an element inside a clip
# container sticks out of it; with CLAY_CLIP_TO_ATTACHED_PARENT it is
# drawn between its own SCISSOR_START and SCISSOR_END commands, with the
# container's box.

heading('8. A modal over the root, and clipped floating elements');
sub declare_floating ($badge_clip_to) {
	box('viewport', sizing_fixed(120), sizing_fixed(50), sub {
		box('cell', sizing_fixed(60), sizing_fixed(30), sub {
			box('badge', sizing_fixed(30), sizing_fixed(16), sub { }, floating => {
				attachTo     => CLAY_ATTACH_TO_PARENT,
				attachPoints => { element => CLAY_ATTACH_POINT_CENTER_CENTER, parent => CLAY_ATTACH_POINT_RIGHT_TOP },
				clipTo       => $badge_clip_to,
				zIndex       => 1,
			});
		});
		box('modal', sizing_fixed(160), sizing_fixed(80), sub {
			box('modal-body', sizing_grow(), sizing_grow());
		}, floating => {
			attachTo     => CLAY_ATTACH_TO_ROOT,
			attachPoints => { element => CLAY_ATTACH_POINT_CENTER_CENTER, parent => CLAY_ATTACH_POINT_CENTER_CENTER },
			expand       => { width => 10, height => 10 },
			zIndex       => 100,
		});
	}, layout => { padding => { left => 70, top => 10 } }, clip => { horizontal => 1, vertical => 1 });
}

sub scissors_around_badge ($commands) {
	my $badge_id = Clay_GetElementId('badge')->{id};
	my ($index)  = grep { $commands->[$_]{id} == $badge_id } 0 .. $#$commands;
	my $before   = $commands->[ $index - 1 ];
	return 'not clipped' unless $before->{commandType} == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START;
	return sprintf 'clipped to %gx%g at (%g, %g)', @{ $before->{boundingBox} }{qw(width height x y)};
}

my $none_commands = lay_out(sub { declare_floating(CLAY_CLIP_TO_NONE) });
say "  $_" for describe_box('modal'), describe_box('modal-body'), describe_box('badge');
say '  (the modal is 160x80 plus 10 on every side; its body still fills 160x80)';
printf "  badge with CLAY_CLIP_TO_NONE: %s\n", scissors_around_badge($none_commands);
my $clipped_commands = lay_out(sub { declare_floating(CLAY_CLIP_TO_ATTACHED_PARENT) });
printf "  badge with CLAY_CLIP_TO_ATTACHED_PARENT: %s\n", scissors_around_badge($clipped_commands);

# ---------------------------------------------------------------------------
# 9. Breaking text at newlines only
# ---------------------------------------------------------------------------
#
# CLAY_TEXT_WRAP_WORDS breaks at spaces and newlines to fit the width;
# CLAY_TEXT_WRAP_NEWLINES only where the text has a "\n", even if a line
# is wider than its parent. CLAY_TEXT_WRAP_NONE never breaks: the whole
# text, "\n" included, is one line.

heading('9. Breaking text at newlines only');
my $poem = "roses are red\nviolets are blue";
for my $mode ([ CLAY_TEXT_WRAP_WORDS, 'WORDS' ], [ CLAY_TEXT_WRAP_NEWLINES, 'NEWLINES' ], [ CLAY_TEXT_WRAP_NONE, 'NONE' ]) {
	my ($wrap_mode, $name) = @$mode;
	my $commands = lay_out(sub {
		box('narrow', sizing_fixed(60), sizing_fit(), sub { text($poem, wrapMode => $wrap_mode) });
	});
	my @lines = map { $_->{renderData}{stringContents} } grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$commands;
	printf "  %-8s in 60 units: %d lines: %s\n", $name, scalar @lines, join ' | ', @lines;
}

# ---------------------------------------------------------------------------
# 10. Telling errors apart
# ---------------------------------------------------------------------------
#
# The error handler receives errorType, one of the CLAY_ERROR_TYPE_*
# constants, next to the human-readable errorText. Compare errorType,
# never the text. Two elements with the same id in one frame give
# CLAY_ERROR_TYPE_DUPLICATE_ID; Clay still lays both out.
#
# The second frame nests sizing groups in a cycle on the width axis:
# outer-a (group 1) holds inner-a (group 2), and outer-b (group 2) holds
# inner-b (group 1). Each outer box is 10 units wider than its inner one
# (padding), so every round of equalizing widens the other group again
# and the widths never settle: CLAY_ERROR_TYPE_SIZING_GROUP_CYCLE. See
# Clay::XS, SIZING GROUPS.

# A FIT box in sizing group $group on the width axis, padded by 5 units.
sub grouped_box ($name, $group, $children = sub { }) {
	box($name, sizing_fit(), sizing_fit(), $children,
		sizingGroup => { width => $group },
		layout      => { padding => padding_all(5) });
	return;
}

heading('10. Telling errors apart');
@clay_errors = ();
lay_out(sub {
	box('toolbar', sizing_grow(), sizing_fit(), sub {
		box('button', sizing_fixed(20), sizing_fixed(20));
		box('button', sizing_fixed(20), sizing_fixed(20));
	});
});
lay_out(sub {
	box('cycle', sizing_fit(), sizing_fit(), sub {
		grouped_box('outer-a', 1, sub { grouped_box('inner-a', 2) });
		grouped_box('outer-b', 2, sub { grouped_box('inner-b', 1) });
	});
});
my %ERROR_HINT = (
	CLAY_ERROR_TYPE_DUPLICATE_ID()       => 'a duplicate id: give every element its own name',
	CLAY_ERROR_TYPE_SIZING_GROUP_CYCLE() => 'sizing groups nested in a cycle: Clay gives up, the groups stay unequal',
);
for my $error (@clay_errors) {
	my $hint = $ERROR_HINT{ $error->{errorType} };
	printf "  %s%s:\n    %s\n", $ERROR_TYPE_NAME{ $error->{errorType} },
		defined $hint ? " ($hint)" : '', $error->{errorText};
}
