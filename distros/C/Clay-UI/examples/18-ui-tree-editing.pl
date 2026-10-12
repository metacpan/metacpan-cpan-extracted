#!/usr/bin/env perl

# 18-ui-tree-editing.pl - Focus, states and editing a live Clay::UI tree.
#
# A small task board: a heading, task cards, a pair of notes and a
# schedule grid. Scripted clicks focus cards, the script marks cards with
# states, removes and filters children, edits the grid row by row and
# finally resizes the UI and swaps its text measurement. Every step
# prints what changed, so the output reads like a log of the session.
# Nothing is drawn; the output is the same on every run.
#
# Shows:
#   - click to focus: a press listener that moves the focus
#   - asking a widget whether it is hovered, pressed or focused
#   - user states next to the derived ones (hovered, pressed, focused)
#   - turning focus off for one widget, and for a whole subclass
#   - finding and removing children with a predicate, guarding text widgets
#   - removing a widget's internal child
#   - two widgets in a row sharing one height
#   - inserting, replacing, removing and clearing grid rows and cells
#   - resizing the UI and replacing its measure_text callback
#
# Features: Clay::UI::Box, Clay::UI::Text, set_focused_widget, interaction, OnPress, is_hovered, is_pressed, is_focused, add_state, remove_state, clear_states, has_state, states, can_focus, accepts_focus, get_children_with, remove_children_with, add_internal_children, remove_internal_children, floating, attach_to, attach_points, CLAY_ATTACH_TO_PARENT, internal_children, layout_children, height_group, Clay::UI::Grid, insert_row, remove_row, replace_row, set_cell, clear_rows, insert_spanning_row, replace_spanning_row, append_row, row_count, is_spanning_row, cell_wrappers, width, height, measure_text, current_revision, bounding_box, pointer_state, Clay::UI::Role::Interaction::Hoverable, Clay::UI::Role::Interaction::Pressable, Clay::UI::Role::Interaction::Focusable
#
# Requires: nothing beyond this distribution.
#
# Run with:
#
#     perl -Ilib -Iblib/lib -Iblib/arch examples/18-ui-tree-editing.pl

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
use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Role::Interaction::Pressable;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Grid;
use Clay::UI::Text;

# Clay::UI ships roles, not classes: each widget class is one line that
# composes the role it needs (see Clay::Manual, GETTING STARTED).
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}

# ---- Widget classes ----
#
# A card is a box that can be hovered, pressed and focused. Clicking does
# not move the focus by itself (Clay::UI knows nothing about what a click
# means): the card's OnPress listener asks the interaction tracker to
# focus it. A card may carry a badge, an internal child: part of the
# card's look, laid out with it, but invisible to children and the
# Container methods. See Clay::UI::Role::Core::Element, add_internal_children.

class Board::Card :strict(params)
	:does(Clay::UI::Box)
	:does(Clay::UI::Role::Interaction::Hoverable)
	:does(Clay::UI::Role::Interaction::Pressable)
	:does(Clay::UI::Role::Interaction::Focusable)
{
	use Clay::XS qw(padding_all CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_RIGHT_TOP);

	field $title :param :reader;
	field $badge;

	ADJUST :params (:$badge_text = undef) {
		$self->add_child(My::Text->new(text => $title, font_size => 10));
		# The listener uses the event's widget, not $self: a closure over
		# $self would keep the card alive through its own listener list.
		$self->on(OnPress => sub ($event) {
			my $card = $event->current_target;
			$card->ui->interaction->set_focused_widget($card) if $card->can_focus;
			return Clay::UI::Enum::Result->HANDLED;
		});
		$self->_add_badge($badge_text) if defined $badge_text;
	}

	method _add_badge ($badge_text) {
		$badge = My::Box->new(
			layout   => { padding => padding_all(2) },
			floating => {
				attach_to     => CLAY_ATTACH_TO_PARENT,
				attach_points => { element => CLAY_ATTACH_POINT_RIGHT_TOP, parent => CLAY_ATTACH_POINT_RIGHT_TOP },
			},
		);
		$badge->add_child(My::Text->new(text => $badge_text, font_size => 8));
		$self->add_internal_children($badge);
		return;
	}

	method has_badge () { return defined $badge ? 1 : 0 }

	method remove_badge () {
		return $self unless defined $badge;
		$self->remove_internal_children($badge);
		undef $badge;
		return $self;
	}
}

# A heading is pressable like a card but never takes the focus. A class
# cannot override a method of a role it composes itself, so the override
# of accepts_focus goes into a subclass. See
# Clay::UI::Role::Interaction::Focusable, accepts_focus.

class Board::Heading :strict(params) :isa(Board::Card) {
	method accepts_focus :override () { return 0 }
}

# Clay::UI::Grid is a role too: a grid class of your own composes it.

class Board::Schedule :strict(params) :does(Clay::UI::Grid) {}

# ---- Build the tree ----

my $COLUMN      = { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 4, padding => padding_all(4) };
my $TASK_LAYOUT = { sizing => { width => sizing_fixed(120) }, padding => padding_all(4) };

my $heading = Board::Heading->new(id => 'heading', title => 'Today');
my %task    = map { ($_ => Board::Card->new(id => "task-$_", title => "Task $_", layout => $TASK_LAYOUT)) } 2 .. 4;
$task{1} = Board::Card->new(id => 'task-1', title => 'Task 1', badge_text => 'NEW', layout => $TASK_LAYOUT);

my $list = My::Box->new(id => 'list', layout => $COLUMN);
$list->add_child(My::Text->new(text => 'Tasks', font_size => 12), $heading, map { $task{$_} } 1 .. 4);

# Two notes side by side, padded differently, so they differ in height.
my $note_a = Board::Card->new(id => 'note-a', title => 'Short note', layout => { padding => padding_all(2) });
my $note_b = Board::Card->new(id => 'note-b', title => 'Padded note', layout => { padding => padding_all(10) });
my $notes  = My::Box->new(id => 'notes', layout => { child_gap => 4 });
$notes->add_child($note_a, $note_b);

my $schedule = Board::Schedule->new(id => 'schedule', cell_gap => 6, row_gap => 2);

my $board = My::Box->new(
	id     => 'board',
	layout => { %$COLUMN, sizing => { width => sizing_grow(), height => sizing_grow() } },
);
$board->add_child($list, $notes, $schedule);

my $ui = Clay::UI->new(
	width        => 320,
	height       => 240,
	root         => $board,
	measure_text => sub ($text, $config, $userdata) { return { width => 6 * length $text, height => $config->{fontSize} } },
);

# ---- Helpers ----

sub heading ($title) {
	say "\n$title";
	return;
}

sub center_of ($widget) {
	my $box = $ui->bounding_box($widget) // die 'center_of: ' . $widget->id . " is not laid out\n";
	return (x => $box->{x} + $box->{width} / 2, y => $box->{y} + $box->{height} / 2);
}

sub flags_of ($card) {
	return sprintf '%s: hovered %d, pressed %d, focused %d', $card->id, $card->is_hovered, $card->is_pressed, $card->is_focused;
}

sub focused_id () {
	my $focused = $ui->interaction->get_focused_widget;
	return defined $focused ? $focused->id : '(none)';
}

sub child_names ($parent) {
	return join ', ', map { $_->id // '"' . $_->text . '"' } @{ $parent->children };
}

sub first_line_of_error ($code) {
	return 'no error' if eval { $code->(); 1 };
	my ($line) = split /\n/, "$@";
	return $line =~ s/ at \S+ line \d+\.?\z//r;
}

# A click is two frames: press, then release, at the widget's centre.
sub click ($widget) {
	my %at = center_of($widget);
	$ui->render(pointer_state => { %at, down => 1 });
	$ui->render(pointer_state => { %at, down => 0 });
	return;
}

sub cell_text ($cell) {
	my $content = $cell->children->[0];
	return defined $content ? $content->text : '';
}

sub show_schedule ($what) {
	my $cells = $schedule->cell_wrappers;
	my @rows  = map {
		$schedule->is_spanning_row($_)
			? '[' . cell_text($cells->[$_][0]) . ']'
			: join(' | ', map { cell_text($_) } @{ $cells->[$_] })
	} 0 .. $schedule->row_count - 1;
	printf "  %-34s %s\n", "$what:", @rows ? join('; ', @rows) : '(no rows)';
	return;
}

sub label ($text) { return My::Text->new(text => $text, font_size => 10) }

# ---- 1. Click to focus ----
#
# Hover, press and focus are tracked by $ui->interaction; is_hovered,
# is_pressed and is_focused ask it. Clay hit-tests against the previous
# frame, so the script renders one frame before it points at anything.

heading('1. Click to focus');
$ui->render;
my %over_task_1 = center_of($task{1});
$ui->render(pointer_state => { %over_task_1, down => 0 });
say '  pointer over task-1:  ', flags_of($task{1});
$ui->render(pointer_state => { %over_task_1, down => 1 });
say '  button pressed:       ', flags_of($task{1});
$ui->render(pointer_state => { %over_task_1, down => 0 });
say '  button released:      ', flags_of($task{1});

printf "  heading can_focus: %d (Board::Heading overrides accepts_focus)\n", $heading->can_focus;
click($heading);
printf "  after clicking the heading the focus stays on %s\n", focused_id();
click($task{3});
printf "  after clicking task-3 the focus is on %s\n", focused_id();

# ---- 2. can_focus ----
#
# Writing can_focus(0) records that the widget should not take the focus;
# a widget that has the focus loses it at once (OnBlur fires).

heading('2. can_focus');
$task{3}->can_focus(0);
printf "  task-3 can_focus(0): can_focus %d, focus now on %s\n", $task{3}->can_focus, focused_id();
click($task{3});
printf "  clicking task-3 again: focus on %s\n", focused_id();
$task{3}->can_focus(1);
click($task{3});
printf "  can_focus(1) and another click: focus on %s\n", focused_id();

# ---- 3. User states and derived states ----
#
# A user state is a name the program sets and clears (add_state,
# remove_state, clear_states); derived states (hovered, pressed, focused,
# disabled) follow the interaction tracker. has_state asks for both, and
# styles can depend on either. See Clay::UI::Role::Style::HasStates.

heading('3. User states and derived states');
$task{3}->add_state('selected')->add_state('urgent');
$task{2}->add_state('done');
$task{4}->add_state('done');
printf "  task-3 states: %s\n", join ', ', sort $task{3}->states;
printf "  task-3 has_state('urgent') %d, has_state('done') %d\n", $task{3}->has_state('urgent') ? 1 : 0, $task{3}->has_state('done') ? 1 : 0;
$task{3}->remove_state('urgent');
printf "  after remove_state('urgent'): %s\n", join ', ', sort $task{3}->states;
$task{3}->clear_states;
printf "  after clear_states: %s (focused is derived and stays)\n", join ', ', sort $task{3}->states;
printf "  add_state('hovered'): %s\n", first_line_of_error(sub { $task{3}->add_state('hovered') });

# ---- 4. Finding and removing children ----
#
# get_children_with and remove_children_with call a predicate for every
# direct child, text widgets included. A text widget's id is undef, so a
# predicate that asks for ids defaults it.

heading('4. Finding and removing children');
say '  children of list: ', child_names($list);
my @tasks = $list->get_children_with(sub { ($_->id // '') =~ /^task-/ });
printf "  tasks by id: %d\n", scalar @tasks;
my @done = $list->get_children_with(sub { $_->can('has_state') && $_->has_state('done') });
printf "  done: %s\n", join ', ', map { $_->id } @done;
$list->remove_children_with(sub { $_->can('has_state') && $_->has_state('done') });
say '  after remove_children_with(done): ', child_names($list);
printf "  a removed card has no parent: %s\n", defined $task{2}->parent ? 'wrong' : 'yes';

# ---- 5. Internal children ----

heading('5. Internal children');
printf "  task-1: children %d, internal_children %d, layout_children %d\n",
	scalar @{ $task{1}->children }, scalar @{ $task{1}->internal_children }, scalar @{ $task{1}->layout_children };
my $badge = $task{1}->internal_children->[0];
$ui->render;
printf "  badge laid out: %s\n", defined $ui->bounding_box($badge) ? 'yes' : 'no';
$task{1}->remove_badge;
$ui->render;
printf "  after remove_badge: internal_children %d, badge laid out: %s, has_badge %d\n",
	scalar @{ $task{1}->internal_children }, defined $ui->bounding_box($badge) ? 'yes' : 'no', $task{1}->has_badge;

# ---- 6. Sharing a height ----
#
# Widgets with the same height_group get the height of the tallest one,
# like width_group does for widths (see Clay::Manual, THE LAYOUT MODEL,
# "Sizing groups"). 0 means no group.

heading('6. Sharing a height');
sub note_heights () {
	return sprintf 'note-a %g high, note-b %g high', $ui->bounding_box($note_a)->{height}, $ui->bounding_box($note_b)->{height};
}
say '  no group:       ', note_heights();
$_->height_group(1) for $note_a, $note_b;
$ui->render;
say '  height_group 1: ', note_heights();

# ---- 7. Editing a grid ----
#
# Grid rows change through the grid's own methods; each takes free
# widgets, checks everything before it changes anything and returns the
# grid. Text widgets are wrapped in a cell the grid creates. See
# Clay::UI::Grid, METHODS.

heading('7. Editing a grid');
$schedule->append_row([ label('09:00'), label('Standup') ]);
$schedule->append_row([ label('11:00'), label('Review') ]);
$schedule->append_row([ label('14:00'), label('Planning') ]);
show_schedule('append_row x3');
$schedule->insert_row(1, [ label('10:00'), label('Pairing') ]);
show_schedule('insert_row(1, ...)');
$schedule->remove_row(2);
show_schedule('remove_row(2)');
$schedule->replace_row(0, [ label('09:15'), label('Standup (late)') ]);
show_schedule('replace_row(0, ...)');
$schedule->set_cell(1, 1, label('Pair review'));
show_schedule('set_cell(1, 1, ...)');
$schedule->insert_spanning_row(0, label('Morning'));
show_schedule('insert_spanning_row(0, ...)');
$schedule->replace_spanning_row(0, label('Monday'));
show_schedule('replace_spanning_row(0, ...)');
printf "  set_cell on the spanning row: %s\n", first_line_of_error(sub { $schedule->set_cell(0, 1, label('x')) });
$ui->render;
my $cells = $schedule->cell_wrappers;
printf "  after render the time column is %g wide in every row: %s\n",
	$ui->bounding_box($cells->[1][0])->{width},
	(grep { $ui->bounding_box($cells->[$_][0])->{width} != $ui->bounding_box($cells->[1][0])->{width} } 1 .. 3) ? 'no' : 'yes';
$schedule->clear_rows;
show_schedule('clear_rows');

# ---- 8. Resizing the UI ----
#
# width and height are setters too. They pass the new size to Clay and
# bump the revision, so a renderer that skips unchanged frames redraws.

heading('8. Resizing the UI');
my $revision = current_revision();
$ui->width(480);
$ui->height(160);
$ui->render;
printf "  ui is %gx%g, board %gx%g, revision bumped: %s\n",
	$ui->width, $ui->height, @{ $ui->bounding_box($board) }{qw(width height)}, current_revision() > $revision ? 'yes' : 'no';

# ---- 9. Replacing measure_text ----
#
# A new measure_text (a larger font, say) also empties Clay's cache of
# old measurements, so the next frame measures every text again.

heading('9. Replacing measure_text');
# The heading has no padding: it is exactly as wide as its text "Today".
printf "  the heading is %g wide\n", $ui->bounding_box($heading)->{width};
$ui->measure_text(sub ($text, $config, $userdata) { return { width => 9 * length $text, height => $config->{fontSize} } });
$ui->render;
printf "  after measure_text(9 units per character) it is %g wide\n", $ui->bounding_box($heading)->{width};
