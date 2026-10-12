#!/usr/bin/env perl

# 12-ui-interaction.pl - A settings dialog driven by scripted input.
#
# The dialog has three option toggles, a summary of the enabled options and
# an Apply / Cancel footer. Nothing is drawn: a scripted list of pointer
# states and key presses goes through $ui->render and Clay::UI's focus
# methods, and every event is logged, so you can follow what each input
# does: pointer and keyboard input in, widget events out. The output is
# the same on every run.
#
# Shows:
#   - button and toggle widget classes composed from interaction roles
#   - a toggle whose fill follows its user state ("checked") and its
#     derived states (hovered, pressed, focused, disabled)
#   - event listeners, bubbling to the dialog, and stopping it there
#   - which widget handled a bubbled event (handled_by)
#   - a custom event class fired by a widget
#   - a click (press, release), a cancelled click (press, drag off,
#     release: armed but not pressed) and a click on a disabled button
#   - Tab / Shift+Tab focus traversal with an explicit tab order
#   - a focused button that disables itself and loses focus
#   - a list widget that rebuilds its children once per frame
#   - a renderer loop that skips frames when nothing changed
#
# Features: Clay::UI, Clay::UI::Box, Clay::UI::Text, render, pointer_state, bounding_box, interaction, is_armed, is_pressed, is_enabled, focus_next, focus_previous, get_focused_widget, can_take_focus, on, fire_event, handled_by, Clay::UI::Events::Event, OnHoverStart, OnHoverStopped, OnPress, OnRelease, OnFocus, OnBlur, Clay::UI::Enum::Result, Clay::UI::Enum::Bubble, Clay::UI::Role::Interaction::Pressable, Clay::UI::Role::Interaction::Focusable, Clay::UI::Role::Interaction::Disableable, Clay::UI::Role::Interaction::HasFocusOrder, default_next_focus, default_previous_focus, has_state, toggle_state, states, Clay::UI::Role::Core::Preparable, request_prepare, prepare_layout, current_revision, laid_out_revision
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/12-ui-interaction.pl

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Revision qw(current_revision);
use Clay::UI::Enum::Result;
use Clay::UI::Enum::Bubble;
use Clay::UI::Events::Event;
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Core::Preparable;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasCornerRadius;
use Clay::UI::Role::Interaction::Pressable;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Interaction::Disableable;
use Clay::UI::Role::Interaction::HasFocusOrder;
use Clay::UI::Text;

# Clay::UI ships roles, not classes: each widget class is one line that
# composes the role it needs (see Clay::Manual, GETTING STARTED).
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}

# ---- A custom event ----
#
# A widget event is a subclass of Clay::UI::Events::Event. event_name is
# the name listeners subscribe to with on(); default_bubble_mode says how
# far it travels up the tree. ALWAYS reaches every ancestor, even when a
# listener on the way returns HANDLED (see Clay::UI::Events::Event).

class Settings::OnToggle :isa(Clay::UI::Events::Event) :strict(params) {
	field $checked :param :reader;

	method event_name :common { 'OnToggle' }
	method default_bubble_mode :common { Clay::UI::Enum::Bubble->ALWAYS }
}

# ---- A push button ----
#
# Clay::UI::Box brings children, layout and styling; the interaction roles
# bring hover and press events (Pressable), focus (Focusable) and the
# 'disabled' flag (Disableable). Clay::UI only arms and presses enabled
# widgets, and a disabled widget cannot take focus.

class Settings::Button :strict(params)
	:does(Clay::UI::Box)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::Disableable)
{
	use Clay::XS qw(sizing_fixed padding_all CLAY_ALIGN_X_CENTER CLAY_ALIGN_Y_CENTER);

	field $title  :param :reader;
	field $action :param;

	# Every button has the same size, so it sets its own layout.
	ADJUST {
		$self->layout({
			sizing          => { width => sizing_fixed(90), height => sizing_fixed(28) },
			padding         => padding_all(4),
			child_alignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
		});
		$self->add_child(My::Text->new(text => $title, font_size => 14));

		# A completed click (OnRelease) runs the action. The listener uses
		# the event's current_target instead of capturing $self: a closure
		# over $self, stored in $self, would keep the button alive forever.
		$self->on(OnRelease => sub ($event) {
			$event->current_target->activate;
			return Clay::UI::Enum::Result->HANDLED;
		});
	}

	# Called by a click and by the Space key.
	method activate () {
		$action->($self);
		return;
	}
}

# ---- A toggle (checkbox row) ----
#
# The toggle does not compose Clay::UI::Box: it leaves out HasBackground and
# HasBorder and contributes its own background and border instead, picked
# from its states every frame. (Keeping them would give two contributors
# for the same keys, and a class cannot replace a method of a role it
# composes.) Clay::UI calls every method named
# contribute_<something> when it builds a widget's declaration (see
# Clay::UI::Role::Core::Element, to_config).

class Settings::Toggle :strict(params)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasCornerRadius)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::Disableable)
{
	use Clay::XS qw(sizing_grow sizing_fixed padding_all CLAY_ALIGN_Y_CENTER);

	field $title :param :reader;
	field $label;

	my %FILL = (
		disabled => [200, 200, 200, 255],
		pressed  => [ 90, 120, 170, 255],
		hovered  => [210, 225, 245, 255],
		checked  => [170, 220, 170, 255],
		idle     => [240, 240, 240, 255],
	);
	my $FOCUS_RING = [ 40,  90, 200, 255];

	ADJUST {
		$self->layout({
			sizing          => { width => sizing_grow(), height => sizing_fixed(28) },
			padding         => padding_all(6),
			child_alignment => { y => CLAY_ALIGN_Y_CENTER },
		});
		$label = My::Text->new(text => "[ ] $title", font_size => 14);
		$self->add_child($label);
		$self->on(OnRelease => sub ($event) {
			$event->current_target->activate;
			return Clay::UI::Enum::Result->HANDLED;
		});
	}

	method is_checked () { return $self->has_state('checked') }

	# 'checked' is a user state (Clay::UI::Role::Style::HasStates, which
	# Pressable, Focusable and Disableable compose): add_state,
	# remove_state and toggle_state set it, and each of them bumps the
	# revision. The label text writer bumps it too, so the next frame
	# shows both. Returns the OnToggle event it fired.
	method activate () {
		$self->toggle_state('checked');
		$label->text(($self->is_checked ? '[x] ' : '[ ] ') . $title);
		my $event = Settings::OnToggle->new(checked => $self->is_checked);
		$self->fire_event($event);
		return $event;
	}

	# The look, from the strongest state down. hovered, pressed, focused
	# and disabled are derived states: has_state asks the interaction
	# tracker (or the disabled flag), so the fill is right in the frame
	# the state changes, with no event listener involved.
	method look () {
		for my $state (qw(disabled pressed hovered checked)) {
			return $state if $self->has_state($state);
		}
		return 'idle';
	}

	method contribute_toggle_look ($config) {
		$config->{background_color} = $FILL{ $self->look };
		return unless $self->has_state('focused');
		$config->{border} = { color => $FOCUS_RING, width => { left => 2, right => 2, top => 2, bottom => 2 } };
		return;
	}
}

# ---- A list that rebuilds itself ----
#
# set_lines only records the lines and calls request_prepare; render then
# calls prepare_layout once, after the frame's events and before its
# layout pass. A listener can call set_lines many times per frame and the
# children are rebuilt once, in time for that same frame.

class Settings::Summary :strict(params)
	:does(Clay::UI::Box)
	:does(Clay::UI::Role::Core::Preparable)
{
	field @lines;
	field $rebuilds :reader = 0;

	method set_lines (@new) {
		@lines = @new;
		return $self->request_prepare;
	}

	method prepare_layout () {
		$rebuilds++;
		$self->clear_children;
		my @shown = @lines ? @lines : ('(no options enabled)');
		$self->add_child(map { My::Text->new(text => $_, font_size => 12) } @shown);
		return;
	}
}

# ---- The dialog: root widget with its own tab order ----
#
# The nearest HasFocusOrder ancestor of the focused widget decides where
# focus_next and focus_previous go. The dialog is the root, so it decides
# for every widget (and when nothing is focused). A disabled widget is
# skipped: can_take_focus is false for it. See Clay::Manual, FOCUS AND
# KEYBOARD.

class Settings::Dialog :strict(params)
	:does(Clay::UI::Box)
	:does(Clay::UI::Role::Interaction::HasFocusOrder)
{
	use Scalar::Util qw(refaddr);

	field @tab_order;

	method set_tab_order (@widgets) {
		@tab_order = @widgets;
		return $self;
	}

	method get_next_focus ()     { return $self->_step_tab_order(1) }
	method get_previous_focus () { return $self->_step_tab_order(-1) }

	method _step_tab_order ($step) {
		my $interaction = $self->ui->interaction;
		my $focused     = $interaction->get_focused_widget;
		my ($at) = defined $focused ? grep { refaddr($tab_order[$_]) == refaddr($focused) } 0 .. $#tab_order : ();

		# A focused widget outside the list falls back to tree order.
		if (defined $focused && !defined $at) {
			return $step > 0 ? $self->default_next_focus : $self->default_previous_focus;
		}
		$at //= $step > 0 ? -1 : scalar @tab_order;
		for my $offset (1 .. scalar @tab_order) {
			my $candidate = $tab_order[ ($at + $step * $offset) % @tab_order ];
			return $candidate if $interaction->can_take_focus($candidate);
		}
		return undef;
	}
}

# ---- Build the tree ----

my %widget;    # id => widget, for the script below

sub log_line ($text) {
	say "    $text";
	return;
}

sub build_dialog () {
	my $dialog = Settings::Dialog->new(
		id     => 'dialog',
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_grow() },
			layout_direction => CLAY_TOP_TO_BOTTOM,
			padding          => padding_all(12),
			child_gap        => 8,
		},
		background_color => [250, 250, 252, 255],
	);

	my @toggles = map {
		Settings::Toggle->new(id => $_->[0], title => $_->[1], disabled => $_->[2], corner_radius => 4)
	} ['dark', 'Dark mode', 0], ['autosave', 'Autosave', 0], ['sync', 'Cloud sync (needs an account)', 1];

	my $summary = Settings::Summary->new(
		id     => 'summary',
		layout => { layout_direction => CLAY_TOP_TO_BOTTOM, padding => padding_all(4), child_gap => 2 },
		background_color => [235, 235, 245, 255],
	);
	$summary->set_lines;

	my $footer = My::Box->new(
		id     => 'footer',
		layout => { sizing => { width => sizing_grow() }, child_gap => 8, child_alignment => { x => CLAY_ALIGN_X_RIGHT } },
	);

	# Apply starts disabled: nothing has changed yet. It applies and then
	# disables itself again; if it had the focus, it loses it right there.
	my $apply = Settings::Button->new(
		id       => 'apply',
		title    => 'Apply',
		disabled => 1,
		action   => sub ($button) {
			log_line('Apply: settings applied');
			$button->disabled(1);
		},
	);
	my $cancel = Settings::Button->new(
		id     => 'cancel',
		title  => 'Cancel',
		action => sub ($button) { log_line('Cancel: dialog closed') },
	);
	# Conventional order on screen: Cancel left, Apply right.
	$footer->add_child($cancel, $apply);

	$dialog->add_child(
		My::Text->new(text => 'Settings', font_size => 18),
		@toggles,
		$summary,
		$footer,
	);
	# Tab reaches Apply before Cancel, unlike the tree order.
	$dialog->set_tab_order(@toggles, $apply, $cancel);

	%widget = map { $_->id => $_ } $dialog, @toggles, $summary, $apply, $cancel;
	return $dialog;
}

# ---- Listeners ----

sub listen_for_logging () {
	for my $id (qw(dark autosave sync apply cancel)) {
		my $widget = $widget{$id};
		for my $name (qw(OnHoverStart OnHoverStopped OnFocus OnBlur)) {
			$widget->on($name => sub ($event) {
				log_line(sprintf '%-14s %s', $name, $event->target->id);
				return Clay::UI::Enum::Result->CONTINUE;
			});
		}
	}

	# Pressable widgets get OnPress when the pointer goes down on them. It
	# bubbles with IF_CONTINUE: the dialog only sees it when every listener
	# below returned CONTINUE. A listener returning anything else
	# (including nothing) stops it. See Clay::Manual, POINTER INPUT, Bubbling.
	$widget{apply}->on(OnPress => sub ($event) {
		log_line('OnPress        apply (returns CONTINUE: the press bubbles on)');
		return Clay::UI::Enum::Result->CONTINUE;
	});
	$widget{cancel}->on(OnPress => sub ($event) {
		log_line('OnPress        cancel (returns HANDLED: the dialog does not see it)');
		return Clay::UI::Enum::Result->HANDLED;
	});
	$widget{dialog}->on(OnPress => sub ($event) {
		log_line(sprintf 'OnPress        bubbled up to %s from %s', $event->current_target->id, $event->target->id);
		return Clay::UI::Enum::Result->HANDLED;
	});

	# The custom event bubbles to the dialog, which keeps the summary and
	# the Apply button up to date.
	$widget{dialog}->on(OnToggle => sub ($event) {
		my $toggle = $event->target;
		log_line(sprintf 'OnToggle       %s is now %s (seen by %s)', $toggle->id, $event->checked ? 'on' : 'off', $event->current_target->id);
		my @enabled = map { $_->title } grep { $_->is_checked } @widget{qw(dark autosave sync)};
		$widget{summary}->set_lines(@enabled);
		$widget{apply}->disabled(0);
		return Clay::UI::Enum::Result->HANDLED;
	});
}

# ---- The renderer loop ----
#
# Every setter that changes what a frame shows bumps the revision. The loop
# remembers the revision it last drew; render's laid_out_revision says which
# revision a frame shows. Changes made during render (by listeners and
# prepare_layout) are part of that frame, so no second frame is needed.
# See Clay::Manual, REDRAWING ONLY WHEN SOMETHING CHANGED.

my $ui;
my $drawn_revision;
my ($frames_drawn, $frames_skipped, $renders_skipped) = (0, 0, 0);

sub tick (%input) {
	# No input and no change since the last drawn frame: skip render too.
	if (!%input && defined $drawn_revision && current_revision() == $drawn_revision) {
		$renders_skipped++;
		log_line('[idle: nothing changed, render skipped]');
		return;
	}
	my $commands = $ui->render(%input);
	if (defined $drawn_revision && $ui->laid_out_revision == $drawn_revision) {
		$frames_skipped++;
		log_line('[frame unchanged, not drawn]');
		return;
	}
	$drawn_revision = $ui->laid_out_revision;
	$frames_drawn++;
	log_line(sprintf '[frame drawn: %d render commands]', scalar @$commands);
	return;
}

# ---- Simulated input ----
#
# Clay hit-tests the pointer against the previous frame's layout, so the
# script looks widgets up with bounding_box after a frame and aims at
# their centres.

sub centre_of ($widget) {
	my $box = $ui->bounding_box($widget) // die "widget '" . $widget->id . "' was not laid out\n";
	return (x => $box->{x} + $box->{width} / 2, y => $box->{y} + $box->{height} / 2);
}

my %EMPTY_SPOT = (x => 4, y => 4);    # dialog padding, over no control

sub pointer_at ($where, $down) {
	my %at = ref $where ? centre_of($where) : %EMPTY_SPOT;
	return (pointer_state => { %at, down => $down });
}

sub step ($title) {
	say "\n$title";
	return;
}

sub press_key ($key) {
	my $interaction = $ui->interaction;
	if ($key eq 'Tab') {
		$interaction->focus_next;
	} elsif ($key eq 'Shift+Tab') {
		$interaction->focus_previous;
	} elsif ($key eq 'Space') {
		my $focused = $interaction->get_focused_widget;
		my $fired   = defined $focused ? $focused->activate : undef;
		# A toggle returns the OnToggle event it fired. After fire_event,
		# handled_by is the first widget whose listener returned HANDLED:
		# the dialog, which the event bubbled up to.
		log_line(sprintf 'OnToggle       handled_by %s', $fired->handled_by->id) if defined $fired;
	} else {
		die "unknown key '$key'\n";
	}
	my $focused = $interaction->get_focused_widget;
	log_line(sprintf '(%s pressed; focus is on %s)', $key, defined $focused ? $focused->id : 'nothing');
	return;
}

sub show_toggle ($id) {
	my $toggle = $widget{$id};
	my @states = sort $toggle->states;
	my $ring   = $toggle->has_state('focused') ? ' with a focus ring' : '';
	log_line(sprintf '%s looks %s%s (states: %s)', $id, $toggle->look, $ring, @states ? join(', ', @states) : 'none');
	return;
}

# ---- Run the script ----

$ui = Clay::UI->new(
	width        => 360,
	height       => 300,
	root         => build_dialog(),
	measure_text => sub ($text, $config, $userdata) {
		my $size = $config->{fontSize} || 16;
		return { width => length($text) * $size * 0.6, height => $size };
	},
);
listen_for_logging();

step('1. First frame (lays out the tree; the summary prepares itself)');
tick();
log_line(sprintf 'summary rebuilt %d time(s)', $widget{summary}->rebuilds);

step('2. Idle tick with no input');
tick();

step('3. Move the pointer onto "Dark mode"');
tick(pointer_at($widget{dark}, 0));
show_toggle('dark');

step('4. Press on it');
tick(pointer_at($widget{dark}, 1));
show_toggle('dark');

step('5. Release: a completed click toggles it and fires OnToggle');
tick(pointer_at($widget{dark}, 0));
show_toggle('dark');
log_line(sprintf 'summary rebuilt %d time(s); Apply enabled: %s', $widget{summary}->rebuilds, $widget{apply}->is_enabled ? 'yes' : 'no');

step('6. Click the disabled "Cloud sync" toggle: hover only, no press');
tick(pointer_at($widget{sync}, 0));
tick(pointer_at($widget{sync}, 1));
tick(pointer_at($widget{sync}, 0));
show_toggle('sync');

step('7. Click Apply: its OnPress bubbles to the dialog');
tick(pointer_at($widget{apply}, 0));
tick(pointer_at($widget{apply}, 1));
tick(pointer_at($widget{apply}, 0));

step('8. Press Cancel, drag off, release: no OnRelease, so no click');
tick(pointer_at($widget{cancel}, 0));
tick(pointer_at($widget{cancel}, 1));
tick(pointer_at(undef, 1));
# Off the button with the button still down: Cancel stays armed (the press
# began on it, so coming back and releasing would still click it) but is
# no longer pressed.
log_line(sprintf 'cancel armed: %s, pressed: %s',
	$ui->interaction->is_armed($widget{cancel}) ? 'yes' : 'no', $widget{cancel}->is_pressed ? 'yes' : 'no');
tick(pointer_at(undef, 0));

step('9. Move within empty space: no state changes');
tick(pointer_state => { x => 6, y => 6, down => 0 });

step('10. Keyboard: Tab, Tab, Space (toggles Autosave, enables Apply), Tab');
press_key('Tab');
press_key('Tab');
press_key('Space');
show_toggle('autosave');
press_key('Tab');
tick();

step('11. Space on the focused Apply: it disables itself and loses focus');
press_key('Space');
tick();

step('12. Tab with nothing focused, then Shift+Tab (skips disabled widgets, wraps)');
press_key('Tab');
press_key('Shift+Tab');
tick();

say "\nFrames drawn: $frames_drawn, frames not drawn: $frames_skipped, renders skipped: $renders_skipped";
