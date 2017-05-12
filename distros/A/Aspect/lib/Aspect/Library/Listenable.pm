package Aspect::Library::Listenable;

# TODO: update docs to explain always_fire, setting handler params
# specifically instead of getting default (event), and event cloning

use strict;
use Carp                               ();
use Scalar::Util                       ();
use Sub::Install                       ();
use Aspect::Modular                    ();
use Aspect::Advice::Before             ();
use Aspect::Library::Listenable::Event ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Modular';

sub import {
	my $into = caller();

	Sub::Install::install_sub( {
		code => $_,
		into => $into,
	} ) foreach qw{
		add_listener
		remove_listener
	};

	return 1;
}

sub get_advice {
	my ($self, $event_name, $pointcut, %event_params) = @_;
	Aspect::Advice::Before->new(
		lexical  => $self->lexical,
		pointcut => $pointcut,
		code     => sub {
			my $context    = $_;
			my $listenable = $context->self;
			my %params     = %event_params;

			local $_;
			return unless has_listeners($listenable, $event_name);

			my $always_fire = delete $params{__always_fire};
			my %old_state = get_listenable_state($listenable, \%params);
			$context->original->( $context->args );
			my %new_state = get_listenable_state($listenable, \%params);

			return if
				!$always_fire &&
				keys %old_state &&
				is_equal_state(\%old_state, \%new_state);

			my @params = $context->args;
			shift @params; # remove $self
			my $event = Aspect::Library::Listenable::Event->new(
				name   => $event_name,
				source => $listenable,
				params => \@params,
				%new_state,
				map {("old_$_" => $old_state{$_})} keys %old_state,
			);

			fire_event($event);
		},
	);
}

sub add_listener ($$$) {
	my ($listenable, $event_name, $listener) = @_;
	Carp::croak "listenable is not a hash based object: [$listenable]"
		unless is_hash($listenable);
	my $key = get_listener_key($event_name);
	$listenable->{$key} = [] unless exists $listenable->{$key};
	my $listeners = get_listeners($listenable, $event_name);
	my $lastIndex = (push @$listeners, $listener) - 1;
	if ( ref $listener eq 'ARRAY' ) { # type 3 listener
		Scalar::Util::weaken( $listeners->[$lastIndex]->[1] );
	} elsif ( ref $listener ne 'CODE' ) { # type 2 listener
		Scalar::Util::weaken( $listeners->[$lastIndex] );
	}
}

sub remove_listener ($$$) {
	my ($listenable, $event_name, $listener) = @_;
	my $listeners = get_listeners($listenable, $event_name);
	Carp::croak "listenable has no listeners for event: [$event_name]"
		unless $listeners;
	my $oldSize = @$listeners;
	foreach my $i (0..@$listeners - 1) {
		my $l = $listeners->[$i];
		if ((ref $l eq 'ARRAY' && $listener eq $l->[1]) || $listener eq $l) {
			splice @$listeners, $i, 1;
			last;
		}
	}
	Carp::croak "listener not found: [$event_name, $listener]"
		if $oldSize == @$listeners;
}

# private helpers -------------------------------------------------------------

sub fire_event {
	my $event = shift;
	my ($source, $event_name) = ($event->source, $event->name);
	return unless has_listeners($source, $event_name);
	notify_listener($_, $event) for @{get_listeners($source, $event_name)};
}

sub notify_listener {
	my ($listener, $event) = @_;
	local $_;
	my $clone = $event->clone;
	my $method_name;
	if (ref $listener eq 'CODE') {
		&$listener($clone);
	} elsif (ref $listener eq 'ARRAY') {
		my $o = $listener->[1];
		return unless defined $o; # could be a dead weak ref
		$method_name = $listener->[0];
		my @params = $listener->[2]?
			map { $event->$_ } @{$listener->[2]}:
			($clone);
		$o->$method_name(@params);
	} else {
		return unless defined $listener; # could be a dead weak ref
		$method_name = 'handle_event_'. $event->name;
		$listener->$method_name($clone);
	}
}

sub has_listeners {
	my ($listenable, $event_name) = @_;
	my $listeners = get_listeners($listenable, $event_name);
	return $listeners && @$listeners;
}

sub get_listeners {
	my ($listenable, $event_name) = @_;
	return $listenable->{get_listener_key($event_name)};
}

sub get_listener_key { '_'. __PACKAGE__. '_'. pop }

sub get_listenable_state {
	my ($listenable, $event_params)  = @_;
	local $_;
	return map {
		my $state_getter = $event_params->{$_};
		$_ => $listenable->$state_getter;
	} keys %$event_params
}

sub is_equal_state {
	my ($old_state, $new_state) = @_;
	for my $key (keys %$new_state) {
		return 0 unless
			is_equal_value($old_state->{$key}, $new_state->{$key});
	}
	return 1;
}

# TODO: need smarter ways to figure out equality
sub is_equal_value {
	my ($old, $new) = @_;
	return
		(!defined $new && !defined $old) ||
		(
			defined $new && defined $old &&
			!ref($old) && !ref($new) &&
			$old eq $new
		);
}

sub is_hash {
	shift =~ /=?([A-Z]+)\(/;
	return $1 eq 'HASH';
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Listenable - Observer pattern with events

=head1 SYNOPSIS

  # The class that we will make listenable
  package Point;
  
  sub new {
     bless { color => 'blue' }, shift;
  }
  
  sub erase {
      print 'erased!';
  }
  
  sub get_color {
      $_[0]->{color};
  }
  
  sub set_color {
      $_[0]->{color} = $_[1];
  }
  
  package main;
  
  use Aspect;
  use Aspect::Library::Listenable;
  
  # Setup the simplest listenable relationship: a signal
  
  # Define the aspect for the listenable relationship
  aspect Listenable => ( Erase => call 'Point::erase' );
  
  # Now add a listener
  my $erase_listener = sub { print shift->as_string };
  add_listener $point, Erase => $erase_listener;
  
  my $point = Point->new;
  $point->erase;
  # prints: "erased! name:Erase, source:Point"
  
  remove_listener $point, Erase => $erase_listener;
  $point->erase;
  # prints: "erased!"
  
  # A more complex relationship: listeners get old and new color values
  # and will only be notified if these values are not equal
  aspect Listenable =>
     (Color => call 'Point::set_color', color => 'get_color');
  
  add_listener $point, Color =>
     my $color_listener = sub { print shift->as_string };
  
  $point->set_color('red');
  # prints: "name:Color, source:Point, color:red, old_color:blue, params:red"

  $point->set_color('red'); # does not print anything, color unchanged
  
  remove_listener $point, Color => $color_listener;
  
  # listeners can be callback, as above, or they can be objects
  
  package ColorListener;
  sub new { bless {}, shift }
  sub handle_event_Color { print "new color: ". shift->color };
  package main;
  
  add_listener $point, Color => my $object_listener = ColorListener->new;
  $point->set_color('green');
  # prints: "new color: green"
  remove_listener $point, Color => $object_listener;
  
  
  # listeners can also be specific methods on objects
  
  package EraseListener;
  sub new { bless {}, shift }
  sub my_erase_handler { print 'heard an erase event!' }
  package main;
  
  add_listener $point, Color =>
     [my_erase_handler => my $method_listener = EraseListener->new]
  $point->erase;
  # prints: "heard an erase event!"
  remove_listener $point, Color => $method_listener;

=head1 DESCRIPTION

A reusable aspect for implementing the Listenable design pattern. It lets
you to define listenables and the events they fire. Then you can
add/remove listeners to these listenables. When specific methods of the
listenable are called, registered listeners will be notified.

Some examples of use are:

=over 4

=item *

A timer that allows registration of listeners. They will receive events
when the timer fires.

=item *

In an MVC application, as a mechanism for registering views as listeners
of models. Then when models change, views receive events, which they
handle by updating the display. Several views can be set as listeners for
any event of any model.

=back

The Listenable pattern is a variation of the basic Observer pattern:

=over 4

=item 1

Listeners can be attached to specific events fired by a listenable.
Listenables can fire several types of events. In the basic Observer
pattern, observers are attached to entire observables.

=item 2

Listeners receive an event as their only parameter. From this event, they
can get its name, source, old/new states of the listenable, and any
parameters that were sent to the listenable method that fired the event.

=back

Because it is implemented using aspects, there is no change required to
the listenable or listener classes. For example, you are not required to
fire events after performing interesting state changes in the listenable.
The aspect will do this for you.

=head1 USING

Creating listenable relationships between objects is done in two steps.
First you must define the relationship between the I<classes>, then you
can instantiate the defined relationship between I<instances> of these
classes.

=head2 DEFINING

Defining the relationships between classes is done once per program run.
This is similar to how methods and classes are defined only once.

Each listenable relationship between classes is defined by one aspect,
answering 3 questions:

=over 4

=item 1

What is the name of the event being fired?

=item 2

What methods on what listenable objects cause events to be fired?

=item 3

What data will be present in the event object, so that listeners can
gather information about the change to the listenable that caused the
event to fire? This is optional. The event could carry no data at all,
except its name and source.

=back

You create a listenable aspect so:

  aspect Listenable => (EVENT_NAME => POINTCUT, EVENT_DATA)

The C<EVENT_DATA> part is optional. The three parameters are your answers
to the questions above:

=over 4

=item EVENT_NAME

The string event name. A listenable can participate in several listenable
aspects, each with a different event name. Another way to describe it, is
that a listenable can fire several types of events.

=item POINTCUT

A pointcut object (L<Aspect::Pointcut>) that selects "hot" methods. After
these methods are run, an event will be fired.

=item EVENT_DATA

Optional hash of keys and values you want to add to the event before it
is fired. They key is the string name of the property that will be given
to the event, and the value is a string name of a method, on the
listenable, that will be called to get the property value. The getter
method on the listenable must exist for this to work. If you set
C<EVENT_DATA>, then change checking will be performed before firing. The
event will only be fired, if the event data has changed. If there is no
C<EVENT_DATA>, the event will always be fired. The C<EVENT_DATA> feature
is useful for providing listeners with more information about the event.
Example: when listening to a selection widget, it may by used for
informing listeners of the item selected.

=back

Here is an example of transforming a selector widget, so that it will
fire an event, right after it has received a click from the user.
Listeners can get the selected index from the event they receive:

  aspect Listenable => (
     ItemSelected   => call 'SelectorWidget::click',
     selected_index => 'selected_index',
  );

This assumes that there exists a method
C<SelectorWidget::selected_index>, that will return the currently
selected item, and a method C<click>, called whenever the user clicks the
widget. The event will only be fired if the C<selected_index> has
changed.

Because the aspect should be created only I<Once> during a program run,
for each listenable relationship type, there are several options for
choosing the place to actually create it:

=over 4

=item *

In the listenable, outside any methods or in some static initializer

=item *

In the top level program unit

=item *

In a Facade over some framework

=item *

In a new class you create, which must be used by the code adding/removing
listeners

=back

Now all that is needed is some way to add and remove listener objects,
from a specific listenable, so that the event will actually be handled by
someone, and not just fired into the void.

=head2 ADDING AND REMOVING LISTENERS

The simplest listener is a C<CODE> ref. It can added and removed so:

  use Aspect::Library::Listenable;
  my $code = sub { print "event!" }
  add_listener $point, Color => $code;    # add
  $point->set_color('red');               # $code will be run
  remove_listener $point, Color => $code; # remove
  $point->set_color('yellow');            # event will not fire

The event object is the only parameter received by the callback.

The other two types of listeners are I<object>, and I<method>:

=over 4

=item 1

Object - the method C<handle_event_EVENT_NAME> will be called.

=item 2

Array ref with two elements- scalar method name and listener object.

=back

When the listener is an object , the method name to be called is computed
from the event name by adding C<handle_event_> in front of the event
name. For example: a car object will call the method
C<handle_event_FrontLeftDoorOpened> on its listeners that are objects.

When the listener is an array ref (method listener), the method name
(1st element) is called on the object (2nd element). When removing this
type of listener, you do not remove the array ref but the listener
object, i.e. exactly like you remove an object listener.

For method listeners, you can also change the parameter list of the
method. Usually, the event is the only parameter to the listener method.
By changing the parameter list, you can turn any existing method into a
listener method, without changing it.

You change the parameter list, by providing a list of event properties,
whose values will become the new parameter list. Here is how to make a
C<Family::set_father_name> run each time C<Person::set_name> is called on
the father object:

  aspect Listenable => (
     NameChange => call 'Person::set_name',
     name => 'name',
  );

  $father = Person->new;
  $family = Family->new;

  add_listener $father, NameChange =>
     [set_father_name => $family, [qw(name)]];

  $father->set_name('dan'); # $family->set_father_name('dan') will be called

=head2 HANDLING EVENTS

Listener code is called with one parameter: the event. Its class is
C<Aspect::Listenable::Event>. All events have at least these properties:

=over 4

=item C<name>

The name of the event as defined in the aspect.

=item C<source>

The listenable object.

=item C<params>

The event was fired because a method was called. In this property you
will find an array ref of the parameters sent to that method.

=back

Besides these properties, you can also access any properties that were
defined to be in the event state, when the listenable aspect was created.
For each such property, there is another, with C<old_> prefixed, which
holds the value of the property on the listenable, I<before> the event
was fired.

You access properties on the event using getters. To get the new color of
a point after a C<Color> event:

  sub handle_event_Color {
     my $event = shift;
     print $event->color;
  }

=head1 CAVEATS

=over 4

=item *

Only works with hash based objects. May use C<Scalar-Footnote> in the
future to get around this, or try to keep listeners in the aspect, not
the listenable.

=item *

Supports removing listeners, but not aspects. Aspects will be removed and
event will stop firing, but listeners will not be cleaned up from
listenables. Setup your aspect only once per relationship type, and call
C<aspect Listenable...> in a void context.

=back

=head1 SEE ALSO

C<Class::Listener>, C<Class::Observable>. Both are object-oriented
solutions to the same problem. Both force you to change the listenable
class, by adding the code to fire events inside your "hot" methods.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Marcel GrE<uuml>nauer E<lt>marcel@cpan.orgE<gt>

Ran Eilam E<lt>eilara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2001 by Marcel GrE<uuml>nauer

Some parts copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
