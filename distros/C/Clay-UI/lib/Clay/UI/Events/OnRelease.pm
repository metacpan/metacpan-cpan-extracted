package Clay::UI::Events::OnRelease;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Events::Event;

class Clay::UI::Events::OnRelease :isa(Clay::UI::Events::Event) :strict(params) {
	field $x      :param :reader = 0;
	field $y      :param :reader = 0;
	field $button :param :reader = 1;

	method event_name :common { 'OnRelease' }
}

1;

__END__

=head1 NAME

Clay::UI::Events::OnRelease - fired when a press is released over an armed widget (a click)

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Time::HiRes qw(time);
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
	my $pressed_at;
	$button->on('OnPress',   sub ($event) { $pressed_at = time; return });
	$button->on('OnRelease', sub ($event) {
		my $held = time - $pressed_at;
		say $held < 0.3 ? 'short click' : 'long press';
		return;
	});

	my $ui = Clay::UI->new(width => 100, height => 100, root => $button);
	$ui->render;
	$ui->render(pointer_state => { x => 30, y => 40, down => 1 });
	$ui->render(pointer_state => { x => 30, y => 40, down => 0 });   # prints "short click"

=head1 DESCRIPTION

C<OnRelease> fires when the pointer button goes up (C<down> changes
from true to false in L<Clay::UI/render>'s C<pointer_state> or in a
synthetic L<Clay::UI::Interaction/update>), at the topmost I<armed>
L<Clay::UI::Role::Interaction::Pressable> still under the pointer: a
completed click. A Pressable is armed when it was under the pointer at
the press (see L<Clay::UI::Events::OnPress>); the target is chosen
among the armed ones by the rule in
L<Clay::UI::Interaction/PRESS AND RELEASE>.

Then every widget is disarmed. So nothing fires when:

=over 4

=item *

the press started elsewhere and the pointer was dragged onto the
widget before the release;

=item *

the pointer was dragged off every armed widget before the release;

=item *

the armed widget was removed from the tree or disabled before the
release.

=back

A press on a button inside a pressable card, dragged off the button and
released over the card, gives the card its C<OnRelease>: the press
armed both.

=over 4

=item Name

C<'OnRelease'>.

=item Received by

The topmost armed, enabled Pressable under the pointer.

=item Bubbling

Bubbles with C<< Clay::UI::Enum::Bubble->IF_CONTINUE >>: the parent
sees the event when the widget has no C<OnRelease> listener or all its
listeners return C<< Clay::UI::Enum::Result->CONTINUE >>.

=item Order

After the frame's hover events and C<OnPress>, before C<OnScroll>.
Dropped when an earlier listener removed the widget from the tree.

=back

Clay::UI has no separate click event: an C<OnRelease> listener is a
click handler.

=head1 ACCESSORS

=head2 x

	my $x = $event->x;

The horizontal pointer position when the release was seen, in layout
units: what Clay reports for the frame in C<render>, or the C<x> passed
to C<update> (default 0).

=head2 y

	my $y = $event->y;

The vertical pointer position, like L</x>.

=head2 button

	my $button = $event->button;

The mouse button, always C<1> (primary) when Clay::UI fires the event:
Clay's pointer state has no buttons. A constructor parameter, so code
that fires its own C<OnRelease> can pass another number.

=head2 Inherited accessors

C<name> is C<'OnRelease'> and C<bubble_mode> is C<IF_CONTINUE>.
C<target> is the released widget, C<current_target> the widget whose
listeners run right now, C<handled_by> and C<result> tell where the
event stopped (see L<Clay::UI::Events::Event>).

=head1 CONSTRUCTOR

	my $event = Clay::UI::Events::OnRelease->new(x => 10, y => 20, button => 1);

All parameters are optional: C<x> and C<y> default to 0, C<button> to
1; C<name> and C<bubble_mode> as in L<Clay::UI::Events::Event/new>.

=head1 CLASS METHODS

=head2 event_name

	my $name = Clay::UI::Events::OnRelease->event_name;    # 'OnRelease'

Returns C<'OnRelease'>, the event name listeners register for with C<on>
and the default C<name> of a new event (see
L<Clay::UI::Events::Event/event_name>).

=head1 SEE ALSO

L<Clay::UI::Events::OnPress>, L<Clay::UI::Role::Interaction::Pressable>,
L<Clay::UI::Interaction/PRESS AND RELEASE>, L<Clay::UI/EVENTS>.

=cut
