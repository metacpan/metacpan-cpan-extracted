package Clay::UI::Role::Core::Preparable;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(refaddr weaken);

use Clay::UI::Revision qw(bump_revision);
use Clay::UI::_error qw(croak_ui);

# Process-wide, like the revision: refaddr => [ the widget (weak), its
# request number ], for every widget whose prepare_layout is due before its
# UI's next layout pass. The request numbers order the widgets of a round.
my %_pending;
my $_next_request = 0;

# Calls prepare_layout on the pending widgets that belong to $ui, until
# none is left (a preparation may request another one). Widgets of other
# UIs, or of none yet, stay pending. Dies when preparations keep
# requesting new ones.
#
# A round prepares parents before their descendants (fewer ancestors
# first), and widgets at the same depth in the order they asked. Each
# widget is checked again right before its preparation: one that an
# earlier preparation of the round moved out of this UI goes back into
# the queue, as it was.
#
# A dying prepare_layout does not stop the round: the other due widgets
# are still prepared (as the remaining events still fire after a listener
# error), then the first error is rethrown. Whatever that round queued
# stays pending for the next render.
use constant _MAX_ROUNDS => 100;

sub _prepare_pending ($ui) {
	for my $round (1 .. _MAX_ROUNDS) {
		_forget_freed();
		my @due = _due_in_order($ui);
		return unless @due;
		delete $_pending{ refaddr $_->[0] } for @due;
		my $first_error;
		for my $entry (@due) {
			my ($widget, $request) = @$entry;
			unless (_belongs_to($widget, $ui)) {
				_queue($widget, $request);
				next;
			}
			local $@;
			eval { $widget->prepare_layout; 1 } or $first_error //= $@ || 'unknown prepare_layout error';
		}
		die $first_error if defined $first_error;
	}
	croak_ui "Clay::UI: widgets kept requesting preparation; " . _MAX_ROUNDS . " rounds of prepare_layout did not settle";
}

# The pending entries of $ui's widgets, as [ widget, request number ] with
# strong references, parents before descendants, then by request.
sub _due_in_order ($ui) {
	my @due = map { [ $_->[0], $_->[1], _depth($_->[0]) ] } grep { _belongs_to($_->[0], $ui) } values %_pending;
	return map { [ @$_[0, 1] ] } sort { $a->[2] <=> $b->[2] || $a->[1] <=> $b->[1] } @due;
}

sub _depth ($widget) {
	my $depth = 0;
	$depth++ while defined( $widget = $widget->parent );
	return $depth;
}

# Queues $widget (weakly) under a request number, unless it is queued.
sub _queue ($widget, $request) {
	my $address = refaddr $widget;
	return if _queued_at($address);
	$_pending{$address} = [ $widget, $request ];
	weaken $_pending{$address}[0];
	return;
}

# The widget queued at $address, or undef (also for a freed one).
sub _queued_at ($address) {
	my $entry = $_pending{$address};
	return $entry ? $entry->[0] : undef;
}

# Forgets the entries of widgets freed while they were queued.
sub _forget_freed () {
	delete $_pending{$_} for grep { !defined $_pending{$_}[0] } keys %_pending;
	return;
}

# The number of entries in the queue, for the tests.
sub _pending_count () {
	return scalar keys %_pending;
}

sub _belongs_to ($widget, $ui) {
	return 0 unless defined $widget;
	my $owner = $widget->ui;
	return defined $owner && refaddr($owner) == refaddr($ui) ? 1 : 0;
}

role Clay::UI::Role::Core::Preparable {
	# Brings the widget's subtree up to date; called by Clay::UI::render
	# after the frame's events, before the layout pass.
	method prepare_layout;

	method request_prepare () {
		_queue($self, $_next_request++);
		bump_revision();
		return $self;
	}

	method is_prepare_pending () {
		my $queued = _queued_at(refaddr $self);
		return defined $queued && refaddr($queued) == refaddr($self) ? 1 : 0;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Core::Preparable - let a widget rebuild its subtree right before the layout pass

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Text;
	use Clay::UI::Role::Core::Preparable;

	class My::Label :strict(params) :does(Clay::UI::Text) {}

	class My::List :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Core::Preparable)
	{
		field @items;

		method add_item ($item) {
			push @items, $item;
			$self->request_prepare;    # cheap: the children are rebuilt once per frame
			return $self;
		}

		method prepare_layout () {
			$self->clear_children;
			$self->add_child(map { My::Label->new(text => $_) } @items);
			return;
		}
	}

	my $list = My::List->new(id => 'list');
	my $ui   = Clay::UI->new(width => 400, height => 300, root => $list);
	$list->add_item($_) for qw(apples pears plums);
	my $commands = $ui->render;    # prepare_layout ran once, then the layout pass

=head1 DESCRIPTION

A widget whose children follow from state of its own (a list of items,
the rows of a table) would have to rebuild them on every change of that
state. With C<Clay::UI::Role::Core::Preparable> it asks to be prepared
instead and rebuilds them once, right before the next frame is laid
out, however many changes came before.

C<request_prepare> puts the widget in a queue. L<Clay::UI/render> calls
the C<prepare_layout> method of every queued widget after the frame's
pointer events and before the layout pass (the part of C<render> that
declares the tree to Clay), so changes the event listeners made are
included.

=over 4

=item *

Only widgets that belong to the rendering UI are prepared (their
C<ui> is that UI). A widget that is not part of a UI yet stays queued
until a UI it belongs to renders. That is checked again right before
each preparation: a widget that an earlier preparation of the same
round detached (a list rebuilding its rows, say) is not prepared and
stays queued.

=item *

Parents are prepared before their descendants: a round prepares the
queued widgets with fewer ancestors first, and widgets with as many
ancestors in the order they called C<request_prepare>. A widget that
rebuilds its subtree therefore runs before the widgets inside it.

=item *

A preparation may change anything (no Clay element is open while it
runs) and may request another preparation, of itself or of other
widgets. C<render> keeps preparing until no request is left, and dies
after 100 rounds with
C<Clay::UI: widgets kept requesting preparation; 100 rounds of prepare_layout did not settle>.


=item *

The queue is shared by all UIs of the process and holds widgets
weakly: a widget freed while it is queued is forgotten (its entry goes
at the next C<render> of any UI).

=back

Compose this role together with a widget role
(L<Clay::UI::Role::Core::Element>, L<Clay::UI::Box>, ...); it uses the
widget's C<ui> method.

=head1 METHODS

=head2 prepare_layout

	method prepare_layout () { ... }

Required: the widget class implements it. It brings the widget (usually
its children) up to date. C<render> calls it with no arguments and
ignores the return value. By the time it runs the widget is no longer
queued, so a C<request_prepare> inside it queues it again.

If C<prepare_layout> dies, the other widgets due in the same round are
still prepared, then C<render> stops preparing: requests made during
that round stay queued for the next C<render>. C<render> still runs the
layout pass and then dies with the first error (or with an earlier
listener error of the same frame).

=head2 request_prepare

	$widget->request_prepare;

Queues the widget for C<prepare_layout> before the next layout pass of
its UI. Queuing a queued widget again changes nothing. Always bumps the
revision (L<Clay::UI::Revision>), so a renderer that skips unchanged
frames draws the next one. Returns the widget.

=head2 is_prepare_pending

	if ($widget->is_prepare_pending) { ... }

Returns 1 while the widget is queued, 0 otherwise.

=head1 SEE ALSO

L<Clay::UI/render>, L<Clay::UI::Revision>, L<Clay::Manual>.

=cut
