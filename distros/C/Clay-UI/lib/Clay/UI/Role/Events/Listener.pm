package Clay::UI::Role::Events::Listener;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(blessed weaken);
use Clay::UI::Enum::Result;
use Clay::UI::_error qw(croak_ui);
use Clay::UI::_validate qw(described_value);

my %OPTIONS = map { $_ => 1 } qw(owner);

# The options of on, checked: an empty hash, or { owner => $object }.
sub _parse_options (@options) {
	croak_ui "Clay::UI::Role::Events::Listener: options must be name => value pairs, got an odd number of values"
		if @options % 2;
	my %options = @options;
	my @unknown = sort grep { !$OPTIONS{$_} } keys %options;
	croak_ui "Clay::UI::Role::Events::Listener: unknown option(s): @unknown (the only option is owner)" if @unknown;
	croak_ui "Clay::UI::Role::Events::Listener: owner must be an object, got " . described_value($options{owner})
		if exists $options{owner} && !blessed $options{owner};
	return \%options;
}

# A listener entry: what Emitter calls with ($event), and for an
# owner-bound listener the owner, held weakly. The call of an
# owner-bound listener passes the owner first and lets the event bubble
# on, without running the handler, once the owner is gone.
sub _entry ($handler, $options) {
	return { call => $handler } unless exists $options->{owner};
	my $owner = $options->{owner};
	weaken $owner;
	my $call = sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless defined $owner;
		return $handler->($owner, $event);
	};
	my $entry = { call => $call, owner => $owner };
	weaken $entry->{owner};
	return $entry;
}

sub _is_live ($entry) {
	return !exists $entry->{owner} || defined $entry->{owner};
}

role Clay::UI::Role::Events::Listener {
	field %_handlers;    # event name => [ listener entry, ... ] in registration order

	method on ($event_name, $handler, @options) {
		croak_ui "Clay::UI::Role::Events::Listener: event name must be a non-empty string"
			unless defined $event_name && length $event_name;
		croak_ui "Clay::UI::Role::Events::Listener: handler must be a coderef"
			unless ref $handler eq 'CODE';
		my $entry = _entry($handler, _parse_options(@options));
		push @{ $self->_live_entries($event_name) }, $entry;
		return $self;
	}

	method handlers_for ($event_name) {
		return [] unless exists $_handlers{$event_name};
		return [ map { $_->{call} } @{ $self->_live_entries($event_name) } ];
	}

	# The entries for $event_name, after dropping the owner-bound ones
	# whose owner is gone.
	method _live_entries ($event_name) {
		my $entries = $_handlers{$event_name} //= [];
		@$entries = grep { _is_live($_) } @$entries;
		return $entries;
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
	$part->on($event_name, sub ($owner, $event) { ... }, owner => $owner);

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

The widget keeps its listeners, so a listener must not capture an object
that holds the widget, or the two keep each other alive and are never
freed. Capturing the widget itself is such a cycle, and so is capturing
the object of a widget class that listens on one of its own parts (a
child, an internal child) when that object holds the part. There are
two ways around it:

=over 4

=item *

A listener that needs the widget it is registered on reads it from the
event (C<< $event->current_target >>) instead of naming the widget's
variable inside the closure:

	$box->on('OnPress', sub ($event) {
		my $box = $event->current_target;    # not the outer $box
		...
		return;
	});

=item *

A listener that needs another object, its I<owner>, is registered with
the L</owner> option and gets the owner as its first argument:

	method build_parts () {
		$_button->on('OnRelease', sub ($self, $event) {
			$self->submit;                   # the owner, not the method's $self
			return Clay::UI::Enum::Result->HANDLED;
		}, owner => $self);
	}

=back

Returns the widget, so calls can be chained. Dies with
C<Clay::UI::Role::Events::Listener: event name must be a non-empty string>
or C<Clay::UI::Role::Events::Listener: handler must be a coderef>, and
for bad options (see below).

=head3 owner

	owner => $object

The only option of C<on>; options follow the handler as name => value
pairs. The owner must be an object (a blessed reference). The widget
keeps it I<weakly>: an owner-bound listener does not keep its owner
alive. While the owner exists, the handler is called with
C<($owner, $event)>, and its return value counts as described above.
Once the owner has been freed, the handler no longer runs: the listener
answers C<CONTINUE>, so it never stops the event from bubbling, and its
entry is dropped from the widget (by the next C<on> or L</handlers_for>
for that event name), so the listeners of owners that are gone do not
pile up.

Name the handler's first parameter after what the owner is to the code
(C<$self> in a method that passes C<< owner => $self >>): the parameter
then hides the method's own C<$self>, so the closure cannot capture it
by mistake.

Dies with C<Clay::UI::Role::Events::Listener: owner must be an object, got ...>,
C<Clay::UI::Role::Events::Listener: unknown option(s): ... (the only option is owner)>
and C<Clay::UI::Role::Events::Listener: options must be name =E<gt> value pairs, got an odd number of values>.

=head2 handlers_for

	my $listeners = $widget->handlers_for($event_name);

Returns a new arrayref of the listeners registered for C<$event_name>,
in registration order (empty when there are none). Each is a coderef to
be called with the event. For a plain listener it is the coderef given
to L</on>; for an owner-bound listener it is a coderef that calls the
handler with the owner and the event, or returns C<CONTINUE> once the
owner is gone. Listeners whose owner is gone are left out (and dropped
from the widget). Changing the arrayref does not change the widget.
L<Clay::UI::Role::Events::Emitter/fire_event> calls it for every widget
the event visits.

Listeners are called I<handlers> in this method's name and in the
error message of L</on> (C<handler must be a coderef>); both words mean
the coderefs registered with C<on>.

=head1 SEE ALSO

L<Clay::UI::Role::Events::Emitter>, L<Clay::UI::Events::Event>,
L<Clay::UI/EVENTS>.

=cut
