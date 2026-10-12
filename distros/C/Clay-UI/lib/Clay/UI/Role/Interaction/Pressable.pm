package Clay::UI::Role::Interaction::Pressable;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Role::Interaction::Hoverable;
use Clay::UI::Events::OnPress;
use Clay::UI::Events::OnRelease;

role Clay::UI::Role::Interaction::Pressable :does(Clay::UI::Role::Interaction::Hoverable) {
	# The UI's interaction tracker owns the state; a widget outside a
	# UI is never pressed.
	method is_pressed () {
		my $ui = $self->ui;
		return defined $ui ? $ui->interaction->is_pressed($self) : 0;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Interaction::Pressable - role for widgets that can be pressed and clicked

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::XS qw(sizing_grow);
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Pressable;

	class My::Button :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Pressable)
	{}

	my $button = My::Button->new(
		id     => 'go',
		layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
	);
	$button->on('OnPress', sub ($event) {
		say 'pressed at ', $event->x, ',', $event->y;
		return;
	});
	$button->on('OnRelease', sub ($event) { say 'clicked'; return });

	my $ui = Clay::UI->new(width => 100, height => 100, root => $button);
	$ui->render;
	$ui->render(pointer_state => { x => 20, y => 30, down => 1 });   # pressed at 20,30
	say $button->is_pressed;                                         # 1
	$ui->render(pointer_state => { x => 20, y => 30, down => 0 });   # clicked

=head1 DESCRIPTION

A widget that composes this role can be pressed. Pressable composes
L<Clay::UI::Role::Interaction::Hoverable>, so a Pressable is also
hovered and gets the hover events.

The UI's interaction tracker fires the press events in the frame in
which it sees the pointer button go down or up; the full rules are in
L<Clay::UI::Interaction/PRESS AND RELEASE>:

=over 4

=item L<Clay::UI::Events::OnPress>

When the button goes down, at exactly one widget: the enabled
Pressable under the pointer that is drawn on top. A button inside a
pressable card gets the press, not the card; of two overlapping
siblings, the later one gets it. Every enabled Pressable under the
pointer becomes I<armed>.

=item L<Clay::UI::Events::OnRelease>

When the button goes up, at the topmost armed Pressable still under the
pointer: a completed click. A press on a button inside a pressable card
that is dragged off the button and released over the card gives the
card its C<OnRelease>, since the press armed both. Releasing over no
armed widget (press, drag off everything, release; or press elsewhere,
drag in, release) fires nothing. Every release disarms all widgets.

=back

Both events bubble with C<IF_CONTINUE>: an ancestor sees the event
when the widget has no listener for it or all its listeners return
C<< Clay::UI::Enum::Result->CONTINUE >>, and it sees the bubbled event,
never a second event of its own.

A Pressable that also composes
L<Clay::UI::Role::Interaction::Disableable> takes no part while
disabled: it is never armed or pressed and gets neither event. A press
over a disabled Pressable is absorbed, as in HTML: a pressable card
around a disabled button gets no C<OnPress> either (see
L<Clay::UI::Interaction/PRESS AND RELEASE>).

Clay::UI has no separate click event; combine C<OnPress> and
C<OnRelease> as you need:

	# A completed click (pressed and released over the button):
	$button->on('OnRelease', sub ($event) { activate(); return });

	# Short click or long press:
	my $down_at;
	$button->on('OnPress',   sub ($event) { $down_at = time; return });
	$button->on('OnRelease', sub ($event) {
		(time - $down_at) < 1 ? short_click() : long_press();
		return;
	});

The role composes L<Clay::UI::Role::Interaction::Hoverable> (and
through it L<Clay::UI::Role::Events::Emitter> and
L<Clay::UI::Role::Style::HasStates>, which provides the derived state
C<pressed>).

=head1 METHODS

=head2 is_pressed

	my $down = $widget->is_pressed;

Returns 1 while the widget is pressed: armed by a press, enabled, under
the pointer, and the button still down, as of the last
L<Clay::UI/render> (or synthetic L<Clay::UI::Interaction/update>).
Dragging off the widget clears it; dragging back on, with the button
still down, sets it again; removing the widget from the tree drops it.
Returns 0 otherwise, and for a widget that does not belong to a
Clay::UI.

=head1 SEE ALSO

L<Clay::UI::Events::OnPress>, L<Clay::UI::Events::OnRelease>,
L<Clay::UI::Interaction/PRESS AND RELEASE>,
L<Clay::UI::Role::Interaction::Hoverable>.

=cut
