package Clay::UI::Events::Event;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(blessed weaken);

use Clay::UI::Enum::Bubble;
use Clay::UI::Enum::Result;
use Clay::UI::_error qw(croak_ui);

class Clay::UI::Events::Event :strict(params) {
	field $name        :param :reader = undef;
	field $bubble_mode :param :reader = undef;

	field $target         :reader = undef;
	field $current_target :reader = undef;
	field $handled_by     :reader = undef;
	field $_dispatched           = 0;

	# Subclasses override these to declare their default event name and
	# bubble policy, so callers can `Clay::UI::Events::OnPress->new`
	# without arguments.
	method event_name :common { 'Event' }
	method default_bubble_mode :common { Clay::UI::Enum::Bubble->IF_CONTINUE }

	ADJUST {
		$name        //= (ref $self)->event_name;
		$bubble_mode //= (ref $self)->default_bubble_mode;
		croak_ui "Clay::UI::Events::Event: 'name' must be a non-empty string"
			unless defined $name && length $name;
		croak_ui "Clay::UI::Events::Event: 'bubble_mode' must be a Clay::UI::Enum::Bubble value"
			unless blessed($bubble_mode) && $bubble_mode->isa('Clay::UI::Enum::Bubble');
	}

	# Set by Clay::UI::Role::Events::Emitter at the start of dispatch. Refuses to
	# overwrite an already-set target so a single event object cannot be
	# silently re-fired with a different originator.
	method _set_target ($widget) {
		croak_ui "Clay::UI::Events::Event: event already dispatched; build a fresh event to fire again"
			if $_dispatched;
		$target = $widget;
		weaken $target;
		$_dispatched = 1;
		return;
	}

	method _set_current_target ($widget) {
		$current_target = $widget;
		weaken $current_target;
		return;
	}

	# Set by the emitter once, at the first node whose handlers stopped
	# the walk (or would have, under ALWAYS).
	method _set_handled_by ($widget) {
		return if defined $handled_by;
		$handled_by = $widget;
		weaken $handled_by;
		return;
	}

	# The outcome of the dispatch so far, as fire_event returns it.
	method result () {
		return defined $handled_by ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE;
	}
}

1;

__END__
=head1 NAME

Clay::UI::Events::Event - base class of Clay::UI events, and how to make your own

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI::Box;
	use Clay::UI::Events::Event;
	use Clay::UI::Enum::Bubble;
	use Clay::UI::Enum::Result;

	class My::Panel :strict(params) :does(Clay::UI::Box) {}

	# A custom event: a subclass with its own name, payload and bubble mode.
	class My::Events::OnSubmit :isa(Clay::UI::Events::Event) :strict(params) {
		field $value :param :reader;

		method event_name          :common { 'OnSubmit' }
		method default_bubble_mode :common { Clay::UI::Enum::Bubble->ALWAYS }
	}

	my $form  = My::Panel->new(id => 'form');
	my $field = My::Panel->new(id => 'field');
	$form->add_child($field);

	$form->on('OnSubmit', sub ($event) {
		say 'form got ', $event->value, ' from ', $event->target->id;
		return Clay::UI::Enum::Result->HANDLED;
	});

	# Fire it at the widget it concerns; it bubbles up to the form.
	my $event  = My::Events::OnSubmit->new(value => 42);
	my $result = $field->fire_event($event);
	say 'handled by ', $event->handled_by->id
		if $result == Clay::UI::Enum::Result->HANDLED;

	# A one-off event needs no subclass:
	$field->fire_event(Clay::UI::Events::Event->new(name => 'OnPing'));

=head1 DESCRIPTION

Every Clay::UI event is an object of this class or of a subclass. An
event has a I<name>, which listeners register for with
C<< $widget->on($name, sub ($event) { ... }) >>
(L<Clay::UI::Role::Events::Listener>), and a I<bubble mode>, which says
whether the event travels from the widget it was fired at (the
I<target>) up to its ancestors (L<Clay::UI::Enum::Bubble>).

A widget that composes L<Clay::UI::Role::Events::Emitter> fires an
event with C<< $widget->fire_event($event) >>
(L<Clay::UI::Role::Events::Emitter/fire_event>). While the event
travels, its accessors tell each listener where it is.

The built-in events are subclasses:
L<Clay::UI::Events::OnHoverStart>, L<Clay::UI::Events::OnHoverStopped>,
L<Clay::UI::Events::OnPress>, L<Clay::UI::Events::OnRelease>,
L<Clay::UI::Events::OnScroll>, L<Clay::UI::Events::OnFocus> and
L<Clay::UI::Events::OnBlur>.

=head1 CONSTRUCTOR

=head2 new

	my $event = Clay::UI::Events::Event->new(%params);

Creates an event. Both parameters are optional; unknown parameters die
(the class is C<:strict(params)>).

=over 4

=item name

The event name, a non-empty string. Default: what the class method
C<event_name> returns (C<'Event'> for this class). Dies with
C<Clay::UI::Events::Event: 'name' must be a non-empty string>.

=item bubble_mode

A L<Clay::UI::Enum::Bubble> value. Default: what the class method
C<default_bubble_mode> returns (C<IF_CONTINUE> for this class). Dies
with C<Clay::UI::Events::Event: 'bubble_mode' must be a Clay::UI::Enum::Bubble value>.

=back

=head1 ACCESSORS

=head2 name

	my $name = $event->name;

The event name listeners register for.

=head2 bubble_mode

	my $mode = $event->bubble_mode;

The L<Clay::UI::Enum::Bubble> value that decides how far the event
travels.

=head2 target

	my $widget = $event->target;

The widget C<fire_event> was called on. It stays the same while the
event bubbles. C<undef> before the event is fired.

=head2 current_target

	my $widget = $event->current_target;

The widget whose listeners are running right now: the target first,
then each ancestor the event bubbles to. C<undef> before the event is
fired.

=head2 handled_by

	my $widget = $event->handled_by;

The first widget at which a listener returned anything but
C<< Clay::UI::Enum::Result->CONTINUE >>, or C<undef> when no listener
did (or the event has not been fired). With C<IF_CONTINUE> and C<NEVER>
it is the widget where the event stopped; with C<ALWAYS> the event
travels on and this names the first such widget.

C<target>, C<current_target> and C<handled_by> are weak references: a
fired event never keeps widgets alive.

=head2 result

	my $result = $event->result;

The outcome of the dispatch so far, as a L<Clay::UI::Enum::Result>
value: C<HANDLED> when C<handled_by> is set, C<CONTINUE> otherwise.
C<fire_event> returns this value.

=head1 CLASS METHODS

Subclasses override these C<:common> methods to give C<new> its
defaults.

=head2 event_name

	method event_name :common { 'OnSubmit' }

The default C<name>. Returns C<'Event'> in this class.

=head2 default_bubble_mode

	method default_bubble_mode :common { Clay::UI::Enum::Bubble->NEVER }

The default C<bubble_mode>. Returns C<< Clay::UI::Enum::Bubble->IF_CONTINUE >>
in this class.

=head1 CUSTOM EVENTS

To give an event a payload, subclass this class:

=over 4

=item 1.

Declare the class with C<:isa(Clay::UI::Events::Event)> and
C<:strict(params)>.

=item 2.

Add the payload as fields with C<:param :reader> (as
L<Clay::UI::Events::OnPress> does with C<x>, C<y> and C<button>).

=item 3.

Override C<event_name> (and C<default_bubble_mode> when
C<IF_CONTINUE> is not right) as C<:common> methods.

=item 4.

Fire a new object with C<< $widget->fire_event($event) >> on a widget
that composes L<Clay::UI::Role::Events::Emitter>, for example any
L<Clay::UI::Box>. Text widgets can listen but not fire.

=back

For an event without payload, C<< Clay::UI::Events::Event->new(name =>
'OnPing') >> is enough. Clay::UI never fires custom events by itself;
fire them from your own listeners or code, for example from an
C<OnRelease> listener of a widget that turns a click into an
C<OnSubmit>.

=head1 FIRING AN EVENT TWICE

An event object is single-use. The first C<fire_event> records the
target; firing the same object again dies with
C<Clay::UI::Events::Event: event already dispatched; build a fresh event to fire again>.
Create a new event for every dispatch.


=head1 SEE ALSO

L<Clay::UI::Role::Events::Emitter>, L<Clay::UI::Role::Events::Listener>,
L<Clay::UI::Enum::Bubble>, L<Clay::UI::Enum::Result>, L<Clay::UI/EVENTS>.

=cut
