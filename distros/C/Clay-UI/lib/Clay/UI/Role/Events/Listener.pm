package Clay::UI::Role::Events::Listener;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Clay::UI::_error qw(croak_ui);

role Clay::UI::Role::Events::Listener {
	field %_handlers;

	method on ($event_name, $handler) {
		croak_ui "Clay::UI::Role::Events::Listener: event name must be a non-empty string"
			unless defined $event_name && length $event_name;
		croak_ui "Clay::UI::Role::Events::Listener: handler must be a coderef"
			unless ref $handler eq 'CODE';
		push @{ $_handlers{$event_name} }, $handler;
		return $self;
	}

	method handlers_for ($event_name) {
		return [] unless exists $_handlers{$event_name};
		return [ @{ $_handlers{$event_name} } ];  # defensive copy
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Events::Listener - role that lets every widget listen to events

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI::Box;
	use Clay::UI::Events::OnPress;
	use Clay::UI::Enum::Result;

	class My::Panel :strict(params) :does(Clay::UI::Box) {}

	my $box = My::Panel->new(id => 'box');
	# Both listeners always run; the return values only decide whether
	# the event moves on to the parent.
	$box->on('OnPress', sub ($event) {    # stops bubbling
		say 'first listener';
		return;
	})->on('OnPress', sub ($event) {
		say 'second listener';
		return Clay::UI::Enum::Result->CONTINUE;
	});

	say scalar @{ $box->handlers_for('OnPress') }, ' listeners';   # 2 listeners
	$box->fire_event(Clay::UI::Events::OnPress->new);    # first listener, second listener

=head1 DESCRIPTION

This role is the I<receiving> half of the Clay::UI event system. Every
widget has it: L<Clay::UI::Role::Core::Element> and
L<Clay::UI::Role::Core::TextNode> compose it, so you never compose it
yourself. Any widget can therefore listen to events fired at it and to
events that bubble up to it from its descendants, whether or not it can
fire events itself (see L<Clay::UI::Role::Events::Emitter>).

Text widgets have the role too, but no event reaches them: a text
widget cannot fire, nothing bubbles through it (it has no descendants),
and Clay::UI fires events only at element widgets. Listen on the
element widget around the text instead.

=head1 METHODS

=head2 on

	$widget->on($event_name, sub ($event) { ... });

Registers a listener: a coderef called with the event object when an
event whose C<name> is C<$event_name> is fired at the widget or bubbles
to it. A widget may have several listeners for one name; they run in
the order they were registered. There is no way to remove a listener.

All listeners of a widget for the event always run, whatever the
earlier ones return. The return values only decide whether the event
moves on to the parent (see L<Clay::UI::Enum::Result>): return
C<< Clay::UI::Enum::Result->CONTINUE >> to let it bubble on. B<Anything
else stops it> from bubbling, including an empty C<return>, C<undef>
and whatever the last statement happens to return; one stopping
listener is enough.

A listener that needs the widget it is registered on should read it
from the event (C<< $event->current_target >>) instead of naming the
widget's variable inside the closure. The widget keeps its listeners,
so a closure that captures the widget makes a reference cycle, and the
widget is never freed:

	$box->on('OnPress', sub ($event) {
		my $box = $event->current_target;    # not the outer $box
		...
		return;
	});

Returns the widget, so calls can be chained. Dies with
C<Clay::UI::Role::Events::Listener: event name must be a non-empty string>
or C<Clay::UI::Role::Events::Listener: handler must be a coderef>.


=head2 handlers_for

	my $listeners = $widget->handlers_for($event_name);

Returns a new arrayref of the listeners registered for C<$event_name>,
in registration order (empty when there are none). Changing the
arrayref does not change the widget.
L<Clay::UI::Role::Events::Emitter/fire_event> calls it for every widget
the event visits.

Listeners are called I<handlers> in this method's name and in the
error message of L</on> (C<handler must be a coderef>); both words mean
the coderefs registered with C<on>.

=head1 SEE ALSO

L<Clay::UI::Role::Events::Emitter>, L<Clay::UI::Events::Event>,
L<Clay::UI/EVENTS>.

=cut
