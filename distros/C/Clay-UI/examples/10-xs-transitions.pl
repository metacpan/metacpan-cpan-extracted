#!/usr/bin/env perl

# 10-xs-transitions.pl - Animated element transitions with Clay::XS.
#
# Clay can animate an element from its old look to its new one over
# several frames. This script declares a few elements, changes them between
# frames and steps the clock in fixed 0.05 second frames, printing the
# values Clay draws each frame: a bar that moves, widens and changes
# colour, a card that dims through its overlay colour, a toast that slides
# in, a badge that fades out, and two chips whose triggers decide whether
# they animate when their panel appears and disappears.
#
# Shows:
#   - one transition handler per context, easing with Clay's own curve
#   - choosing what animates by combining transition property flags
#   - an enter transition: the element starts from a state the script picks
#   - an exit transition: a removed element keeps being drawn until it ends
#   - where an exiting element stays among its siblings (siblingOrdering)
#   - enter and exit triggers: animating, or not, together with the parent
#   - an overlay colour that tints an element and its children
#   - the ease-out curve on its own, without a layout
#
# Features: Clay_SetTransitionHandlers, Clay_EaseOut, transition, duration, properties, interactionHandling, CLAY_TRANSITION_DISABLE_INTERACTIONS_WHILE_TRANSITIONING_POSITION, enter, hasSetInitial, trigger, CLAY_TRANSITION_ENTER_SKIP_ON_FIRST_PARENT_FRAME, CLAY_TRANSITION_ENTER_TRIGGER_ON_FIRST_PARENT_FRAME, exit, hasSetFinal, CLAY_TRANSITION_EXIT_SKIP_WHEN_PARENT_EXITS, CLAY_TRANSITION_EXIT_TRIGGER_WHEN_PARENT_EXITS, siblingOrdering, CLAY_EXIT_TRANSITION_ORDERING_NATURAL_ORDER, overlayColor, CLAY_TRANSITION_PROPERTY_X, CLAY_TRANSITION_PROPERTY_POSITION, CLAY_TRANSITION_PROPERTY_WIDTH, CLAY_TRANSITION_PROPERTY_Y, CLAY_TRANSITION_PROPERTY_HEIGHT, CLAY_TRANSITION_PROPERTY_BOUNDING_BOX, CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR, CLAY_TRANSITION_PROPERTY_OVERLAY_COLOR, CLAY_TRANSITION_STATE_ENTERING, CLAY_TRANSITION_STATE_TRANSITIONING, CLAY_TRANSITION_STATE_EXITING, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/10-xs-transitions.pl

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

my $FRAME_TIME  = 0.05;    # seconds per simulated frame
my $DURATION    = 0.25;    # seconds per transition, so five frames
my $FRAME_COUNT = 37;

# ---------------------------------------------------------------------------
# Readable names for constants
# ---------------------------------------------------------------------------

# Only the single-bit flags: the combined ones (POSITION, DIMENSIONS,
# BOUNDING_BOX, BORDER) are ORs of these.
my @PROPERTY_FLAGS = (
	[ CLAY_TRANSITION_PROPERTY_X,                'X' ],
	[ CLAY_TRANSITION_PROPERTY_Y,                'Y' ],
	[ CLAY_TRANSITION_PROPERTY_WIDTH,            'WIDTH' ],
	[ CLAY_TRANSITION_PROPERTY_HEIGHT,           'HEIGHT' ],
	[ CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR, 'BACKGROUND_COLOR' ],
	[ CLAY_TRANSITION_PROPERTY_OVERLAY_COLOR,    'OVERLAY_COLOR' ],
	[ CLAY_TRANSITION_PROPERTY_CORNER_RADIUS,    'CORNER_RADIUS' ],
	[ CLAY_TRANSITION_PROPERTY_BORDER_COLOR,     'BORDER_COLOR' ],
	[ CLAY_TRANSITION_PROPERTY_BORDER_WIDTH,     'BORDER_WIDTH' ],
);

sub property_names ($properties) {
	my @names = map { $_->[1] } grep { $properties & $_->[0] } @PROPERTY_FLAGS;
	return @names ? join('|', @names) : 'NONE';
}

my %TRANSITION_STATE_NAME = (
	CLAY_TRANSITION_STATE_IDLE()          => 'IDLE',
	CLAY_TRANSITION_STATE_ENTERING()      => 'ENTERING',
	CLAY_TRANSITION_STATE_TRANSITIONING() => 'TRANSITIONING',
	CLAY_TRANSITION_STATE_EXITING()       => 'EXITING',
);

sub color_text ($color) {
	return sprintf '(%3.0f,%3.0f,%3.0f,%3.0f)', @$color{qw(r g b a)};
}

# ---------------------------------------------------------------------------
# The ease-out curve on its own
# ---------------------------------------------------------------------------

# Clay_EaseOut needs no context: give it the start and end states and how
# far along the transition is. It eases every property selected in
# properties and leaves the rest at their initial value.
say 'Clay_EaseOut, x from 0 to 100 and alpha from 0 to 255 over 1 second:';
for my $tenth (0 .. 10) {
	my $eased = Clay_EaseOut({
		elapsedTime => $tenth / 10,
		duration    => 1,
		properties  => CLAY_TRANSITION_PROPERTY_X | CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR,
		initial     => { boundingBox => { x => 0 },   backgroundColor => [0, 0, 0, 0] },
		target      => { boundingBox => { x => 100 }, backgroundColor => [0, 0, 0, 255] },
	});
	printf "    t=%.1f  x=%6.2f  alpha=%6.2f%s\n", $tenth / 10,
		$eased->{current}{boundingBox}{x}, $eased->{current}{backgroundColor}{a},
		$eased->{complete} ? '  complete' : '';
}
say '';

# ---------------------------------------------------------------------------
# Context and transition handlers
# ---------------------------------------------------------------------------

my $ctx = Clay_Initialize(
	Clay_MinMemorySize(),
	{ width => 400, height => 200 },
	sub ($err, $userdata) { warn "Clay error: $err->{errorText}\n" },
);
Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
	my $font_size = $config->{fontSize} || 16;
	return { width => length($text) * $font_size * 0.55, height => $font_size };
});

# What the handlers saw this frame, printed by the frame loop.
my @handler_calls;

# Clay calls the handler once per frame for every element whose transition
# is running. It gets no element id, so one handler serves all elements;
# Clay_EaseOut computes the in-between state, and whatever ends up in
# $args->{current} is what Clay draws. Returning true ends the transition.
# $args->{properties} holds only the configured properties that changed:
# the bar asks for POSITION (X | Y) but only moves sideways, so it reads X.
sub ease_every_element ($args, $userdata) {
	my $eased = Clay_EaseOut($args);
	$args->{current} = $eased->{current};
	push @handler_calls, sprintf '%s %s at %.2fs',
		$TRANSITION_STATE_NAME{ $args->{transitionState} }, property_names($args->{properties}), $args->{elapsedTime};
	return $eased->{complete};
}

# Called once when an element with enter => { hasSetInitial => 1 } appears:
# it gets the state the element will end up in and returns where the enter
# transition starts. Here: 30 pixels lower and fully transparent.
sub start_below_and_transparent ($target, $properties, $userdata) {
	my %initial = %$target;
	$initial{boundingBox}     = { %{ $target->{boundingBox} }, y => $target->{boundingBox}{y} + 30 };
	$initial{backgroundColor} = { %{ $target->{backgroundColor} }, a => 0 };
	return \%initial;
}

# Called once when an element with exit => { hasSetFinal => 1 } disappears:
# it gets the element's last state and returns where the exit transition
# ends. Here: no height and fully transparent.
sub end_flat_and_transparent ($initial, $properties, $userdata) {
	my %final = %$initial;
	$final{boundingBox}     = { %{ $initial->{boundingBox} }, height => 0 };
	$final{backgroundColor} = { %{ $initial->{backgroundColor} }, a => 0 };
	return \%final;
}

Clay_SetTransitionHandlers(\&ease_every_element, \&start_below_and_transparent, \&end_flat_and_transparent);

# ---------------------------------------------------------------------------
# The layout, driven by %ui
# ---------------------------------------------------------------------------

my %ui = (
	bar_moved   => 0,    # bar on the right, wide and orange
	card_dimmed => 0,    # card tinted grey through overlayColor
	show_badge  => 1,
	show_toast  => 0,
	show_panel  => 0,    # a panel holding two chips
);

sub declare_bar_track () {
	Clay__OpenElementWithId( Clay_GetElementId('track') );
	Clay__ConfigureOpenElement({
		layout => {
			sizing         => { width => sizing_grow(), height => sizing_fixed(40) },
			padding        => padding_all(4),
			# Moving the bar means changing where its parent puts it.
			childAlignment => { x => $ui{bar_moved} ? CLAY_ALIGN_X_RIGHT : CLAY_ALIGN_X_LEFT },
		},
		backgroundColor => [220, 220, 228, 255],
	});
		Clay__OpenElementWithId( Clay_GetElementId('bar') );
		Clay__ConfigureOpenElement({
			layout => {
				sizing => { width => sizing_fixed($ui{bar_moved} ? 160 : 80), height => sizing_grow() },
			},
			backgroundColor => $ui{bar_moved} ? [230, 140, 40, 255] : [50, 100, 200, 255],
			transition      => {
				duration   => $DURATION,
				# POSITION is X | Y. Only the properties listed here
				# animate; anything else changes at once.
				properties => CLAY_TRANSITION_PROPERTY_POSITION
					| CLAY_TRANSITION_PROPERTY_WIDTH
					| CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR,
				# Pointer hit tests skip the bar while it is moving.
				interactionHandling => CLAY_TRANSITION_DISABLE_INTERACTIONS_WHILE_TRANSITIONING_POSITION,
			},
		});
		Clay__CloseElement();
	Clay__CloseElement();
}

sub declare_card () {
	Clay__OpenElementWithId( Clay_GetElementId('card') );
	Clay__ConfigureOpenElement({
		layout => {
			sizing  => { width => sizing_fixed(100), height => sizing_fixed(60) },
			padding => padding_all(8),
		},
		backgroundColor => [255, 255, 255, 255],
		# The overlay colour is mixed over the element and all its
		# children, by its alpha; alpha 0 leaves them untouched.
		overlayColor => $ui{card_dimmed} ? [90, 90, 90, 160] : [90, 90, 90, 0],
		transition   => {
			duration   => $DURATION,
			properties => CLAY_TRANSITION_PROPERTY_OVERLAY_COLOR,
		},
	});
		Clay__OpenTextElement('card', { fontSize => 14, textColor => [0, 0, 0, 255] });
	Clay__CloseElement();
}

sub declare_badge () {
	Clay__OpenElementWithId( Clay_GetElementId('badge') );
	Clay__ConfigureOpenElement({
		layout          => { sizing => { width => sizing_fixed(60), height => sizing_fixed(60) } },
		backgroundColor => [60, 170, 90, 255],
		transition      => {
			duration   => $DURATION,
			properties => CLAY_TRANSITION_PROPERTY_HEIGHT | CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR,
			exit       => {
				hasSetFinal     => 1,
				# Where the exiting badge goes among the row's
				# children: at its old place. The default,
				# UNDERNEATH_SIBLINGS, makes it the first child (drawn
				# first, so under the card, and at the card's x);
				# ABOVE_SIBLINGS makes it the last child (drawn last).
				# Either way its siblings close the gap at once.
				siblingOrdering => CLAY_EXIT_TRANSITION_ORDERING_NATURAL_ORDER,
			},
		},
	});
	Clay__CloseElement();
}

sub declare_toast () {
	Clay__OpenElementWithId( Clay_GetElementId('toast') );
	Clay__ConfigureOpenElement({
		layout          => { sizing => { width => sizing_fixed(120), height => sizing_fixed(60) } },
		backgroundColor => [40, 40, 50, 255],
		transition      => {
			duration   => $DURATION,
			properties => CLAY_TRANSITION_PROPERTY_Y | CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR,
			enter      => { hasSetInitial => 1 },
		},
	});
	Clay__CloseElement();
}

# Two chips that appear and disappear together with their panel. Both
# have enter and exit transitions; only the triggers differ. The default
# triggers skip an element's enter transition when its parent appears in
# the same frame, and its exit transition when its parent disappears.
sub declare_chip ($name, $enter_trigger, $exit_trigger) {
	Clay__OpenElementWithId( Clay_GetElementId($name) );
	Clay__ConfigureOpenElement({
		layout          => { sizing => { width => sizing_fixed(80), height => sizing_fixed(20) } },
		backgroundColor => [150, 80, 180, 255],
		transition      => {
			duration   => $DURATION,
			# BOUNDING_BOX is POSITION | DIMENSIONS, that is X | Y |
			# WIDTH | HEIGHT: the enter state (30 pixels lower) and the
			# exit state (no height) both need it.
			properties => CLAY_TRANSITION_PROPERTY_BOUNDING_BOX | CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR,
			enter      => { hasSetInitial => 1, trigger => $enter_trigger },
			exit       => { hasSetFinal   => 1, trigger => $exit_trigger },
		},
	});
	Clay__CloseElement();
}

sub declare_panel () {
	Clay__OpenElementWithId( Clay_GetElementId('panel') );
	Clay__ConfigureOpenElement({ layout => { padding => padding_all(5), childGap => 10 } });
		declare_chip('chip-skip', CLAY_TRANSITION_ENTER_SKIP_ON_FIRST_PARENT_FRAME, CLAY_TRANSITION_EXIT_SKIP_WHEN_PARENT_EXITS);
		declare_chip('chip-play', CLAY_TRANSITION_ENTER_TRIGGER_ON_FIRST_PARENT_FRAME, CLAY_TRANSITION_EXIT_TRIGGER_WHEN_PARENT_EXITS);
	Clay__CloseElement();
}

sub declare_page () {
	Clay__OpenElementWithId( Clay_GetElementId('page') );
	Clay__ConfigureOpenElement({
		layout => {
			sizing          => { width => sizing_grow(), height => sizing_grow() },
			layoutDirection => CLAY_TOP_TO_BOTTOM,
			padding         => padding_all(10),
			childGap        => 10,
		},
	});
		declare_bar_track();
		Clay__OpenElementWithId( Clay_GetElementId('row') );
		Clay__ConfigureOpenElement({ layout => { childGap => 10 } });
			declare_card();
			declare_badge() if $ui{show_badge};
			declare_toast() if $ui{show_toast};
		Clay__CloseElement();
		declare_panel() if $ui{show_panel};
	Clay__CloseElement();
}

# ---------------------------------------------------------------------------
# Reading the drawn values back from the render commands
# ---------------------------------------------------------------------------

sub find_command ($commands, $name, $type) {
	my $id = Clay_GetElementId($name)->{id};
	my ($found) = grep { $_->{id} == $id && $_->{commandType} == $type } @$commands;
	return $found;
}

# Clay emits no RECTANGLE for a fully transparent background, nor for an
# element that is gone (removed, and its exit transition over).
sub describe_rectangle ($commands, $name, @fields) {
	my $cmd = find_command($commands, $name, CLAY_RENDER_COMMAND_TYPE_RECTANGLE);
	return "$name not drawn" unless $cmd;
	my $box   = $cmd->{boundingBox};
	my @parts = map { sprintf '%s=%.1f', $_, $box->{$_} } @fields;
	return join ' ', $name, @parts, color_text( $cmd->{renderData}{backgroundColor} );
}

# An element with an overlay colour is bracketed by OVERLAY_COLOR_START /
# OVERLAY_COLOR_END commands; the start carries the colour. Like
# rectangles, they are left out while the overlay's alpha is 0.
sub describe_overlay ($commands, $name) {
	my $cmd = find_command($commands, $name, CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START);
	return "$name overlay " . ($cmd ? color_text( $cmd->{renderData}{color} ) : 'not drawn');
}

# ---------------------------------------------------------------------------
# Frame loop
# ---------------------------------------------------------------------------

# What changes before which frame, and which elements the frame prints.
# Frames 1 and 2 establish the starting look: Clay only animates changes
# it has seen a previous state for.
my @timeline = (
	{ from => 1, shows => [ [ 'bar', qw(x width) ], ['card'] ] },
	{ from => 3, shows => [ [ 'bar', qw(x width) ], ['card'] ],
	  change => sub { $ui{bar_moved} = 1; $ui{card_dimmed} = 1; 'bar moves right, widens, turns orange; card dims' } },
	{ from => 10, shows => [ [ 'badge', qw(x height) ] ],
	  change => sub { $ui{show_badge} = 0; 'badge removed' },
	  explain => [
		'siblingOrdering NATURAL_ORDER keeps the exiting badge at its old x (120);',
		'the default UNDERNEATH_SIBLINGS would draw it first, at the card\'s x (10)',
	  ] },
	{ from => 16, shows => [ [ 'toast', 'y' ] ],
	  change => sub { $ui{show_toast} = 1; 'toast added' } },
	{ from => 23, shows => [ [ 'chip-skip', 'y' ], [ 'chip-play', qw(y height) ] ],
	  change => sub { $ui{show_panel} = 1; 'panel added with chip-skip and chip-play' },
	  explain => [
		'chip-skip, enter trigger SKIP_ON_FIRST_PARENT_FRAME: drawn at once, no enter transition',
		'chip-play, enter trigger TRIGGER_ON_FIRST_PARENT_FRAME: enters with its panel',
	  ] },
	# Removed right after its enter transition ends: the exit starts from
	# the chip's current look.
	{ from => 30, shows => [ [ 'chip-skip', 'y' ], [ 'chip-play', qw(y height) ] ],
	  change => sub { $ui{show_panel} = 0; 'panel removed' },
	  explain => [
		'chip-skip, exit trigger SKIP_WHEN_PARENT_EXITS: gone at once with its panel',
		'chip-play, exit trigger TRIGGER_WHEN_PARENT_EXITS: exits where it was',
	  ] },
);

sub timeline_entry_for ($frame) {
	my ($entry) = grep { $_->{from} <= $frame } reverse @timeline;
	return $entry;
}

# The card is described by its overlay, everything else by its rectangle.
sub describe_element ($commands, $name, @fields) {
	return describe_overlay($commands, $name) if $name eq 'card';
	return describe_rectangle($commands, $name, @fields);
}

for my $frame (1 .. $FRAME_COUNT) {
	my $entry = timeline_entry_for($frame);
	if ($entry->{from} == $frame && $entry->{change}) {
		say '-- ' . $entry->{change}->();
		say "   ($_)" for @{ $entry->{explain} // [] };
	}
	@handler_calls = ();

	Clay_BeginLayout();
	declare_page();
	# The delta time advances every running transition.
	my $commands = Clay_EndLayout($FRAME_TIME);

	my @columns = map { describe_element($commands, @$_) } @{ $entry->{shows} };
	printf "frame %2d  %s\n", $frame, join('  |  ', @columns);
	say "          handler: $_" for @handler_calls;
}
