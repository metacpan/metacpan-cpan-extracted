package Clay::UI::Role::Events::Emitter;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(blessed);

use Clay::UI::Enum::Bubble;
use Clay::UI::Enum::Result;
use Clay::UI::Role::Layout::HasParent;
use Clay::UI::Role::Events::Listener;
use Clay::UI::_error qw(croak_ui);

role Clay::UI::Role::Events::Emitter :does(Clay::UI::Role::Layout::HasParent)
                                     :does(Clay::UI::Role::Events::Listener) {
	method fire_event ($event) {
		croak_ui "Clay::UI::Role::Events::Emitter: fire_event needs a Clay::UI::Events::Event instance"
			unless blessed($event) && $event->isa('Clay::UI::Events::Event');

		$event->_set_target($self);  # dies on re-fire

		my $mode    = $event->bubble_mode;
		my $always  = Clay::UI::Enum::Bubble->ALWAYS;
		my $never   = Clay::UI::Enum::Bubble->NEVER;
		my $cont    = Clay::UI::Enum::Result->CONTINUE;
		my $handled = Clay::UI::Enum::Result->HANDLED;

		my $node = $self;
		while (defined $node) {
			$event->_set_current_target($node);
			my $list = $node->handlers_for($event->name);

			my $any_stop = 0;
			for my $handler (@$list) {
				my $result = $handler->($event);
				$any_stop = 1 unless defined($result) && blessed($result) && $result == $cont;
			}

			if ($any_stop) {
				$event->_set_handled_by($node);
				return $handled if $mode != $always;
			}
			return $event->result if $mode == $never;

			$node = $node->parent;
		}
		return $event->result;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Events::Emitter - role that lets a widget fire events

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI::Box;                 # composes Clay::UI::Role::Events::Emitter
	use Clay::UI::Events::Event;
	use Clay::UI::Enum::Result;

	class My::Panel :strict(params) :does(Clay::UI::Box) {}

	my $toolbar = My::Panel->new(id => 'toolbar');
	my $button  = My::Panel->new(id => 'save');
	$toolbar->add_child($button);
	$toolbar->on('OnSave', sub ($event) {
		say 'toolbar: ', $event->target->id, ' wants to save';
		return;
	});

	my $event  = Clay::UI::Events::Event->new(name => 'OnSave');
	# no listener on the button: bubbles to the toolbar
	my $result = $button->fire_event($event);
	say 'handled by ', $event->handled_by->id if $result == Clay::UI::Enum::Result->HANDLED;

=head1 DESCRIPTION

This role is the I<sending> half of the Clay::UI event system: it gives
a widget the L</fire_event> method. The I<receiving> half, C<on>, is
L<Clay::UI::Role::Events::Listener>, which every widget has.

L<Clay::UI::Box> composes this role, and so do
L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Role::Interaction::Pressable>,
L<Clay::UI::Role::Interaction::Focusable> and
L<Clay::UI::Role::Layout::HasScroll>, whose events Clay::UI fires
through it. Text widgets (L<Clay::UI::Text>) can register listeners,
but no event reaches a text widget: it cannot fire, nothing bubbles
through it (it is a leaf, and events bubble from a widget to its
ancestors), and Clay::UI fires events only at element widgets.

The role composes L<Clay::UI::Role::Layout::HasParent> (for the walk up
the C<parent> chain) and L<Clay::UI::Role::Events::Listener>.

=head1 METHODS

=head2 fire_event

	my $result = $widget->fire_event($event);

Dispatches C<$event>, a L<Clay::UI::Events::Event> object, starting at
this widget:

=over 4

=item 1.

Records this widget as C<< $event->target >>.

=item 2.

Sets C<< $event->current_target >> to the current widget (this widget
first) and calls each of its listeners for C<< $event->name >>, in
registration order, with the event as the only argument. All
listeners of the widget always run; their return values only decide
whether the event moves on to the parent (step 3). A listener I<stops>
the event when it returns anything but
C<< Clay::UI::Enum::Result->CONTINUE >>; the first widget where that
happens becomes C<< $event->handled_by >>.

=item 3.

Moves on to the parent and repeats step 2, as the event's bubble mode
allows: C<ALWAYS> always moves on, C<IF_CONTINUE> moves on only when no
listener of the current widget stopped the event, C<NEVER> never does
(see L<Clay::UI::Enum::Bubble>). The walk ends at the root widget.

=back

Returns C<< Clay::UI::Enum::Result->HANDLED >> when some listener
stopped the event, otherwise C<< Clay::UI::Enum::Result->CONTINUE >>
(no listener at all is C<CONTINUE> too). The same value is available
afterwards as C<< $event->result >>.

Dies with
C<Clay::UI::Role::Events::Emitter: fire_event needs a Clay::UI::Events::Event instance>,
and with
C<Clay::UI::Events::Event: event already dispatched; build a fresh event to fire again>
for an event object that was fired before.


A listener that dies ends the dispatch at once: the remaining
listeners and ancestors are skipped and C<fire_event> dies with that
error. (When Clay::UI fires events in L<Clay::UI/render> or
L<Clay::UI::Interaction/update>, it catches the error, fires the
remaining events of the frame and rethrows the first error
afterwards.)

The widget does not need to belong to a L<Clay::UI>; firing works on
any widget tree.

=head1 SEE ALSO

L<Clay::UI::Role::Events::Listener>, L<Clay::UI::Events::Event>,
L<Clay::UI::Enum::Bubble>, L<Clay::UI::Enum::Result>.

=cut
