package Clay::UI::Events::OnPress;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Events::Event;

class Clay::UI::Events::OnPress :isa(Clay::UI::Events::Event) :strict(params) {
	field $x      :param :reader = 0;
	field $y      :param :reader = 0;
	field $button :param :reader = 1;

	method event_name :common { 'OnPress' }
}

1;

__END__

=head1 NAME

Clay::UI::Events::OnPress - fired at the topmost pressable widget when the pointer goes down

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

	my $ui = Clay::UI->new(width => 100, height => 100, root => $button);
	$ui->render;
	$ui->render(pointer_state => { x => 30, y => 40, down => 1 });   # prints "pressed at 30,40"

=head1 DESCRIPTION

C<OnPress> fires when the pointer button goes down (C<down> changes
from false to true in L<Clay::UI/render>'s C<pointer_state> or in a
synthetic L<Clay::UI::Interaction/update>), at exactly one
L<Clay::UI::Role::Interaction::Pressable>: the enabled Pressable under
the pointer that is drawn on top. A button inside a pressable card gets
it, not the card. The precise rule is in
L<Clay::UI::Interaction/PRESS AND RELEASE>. A press over no enabled
Pressable fires nothing.

The press also I<arms> every enabled Pressable under the pointer, which
is what makes a later L<Clay::UI::Events::OnRelease> possible.

=over 4

=item Name

C<'OnPress'>.

=item Received by

The topmost enabled Pressable under the pointer. A disabled widget
(L<Clay::UI::Role::Interaction::Disableable>) never receives it.

=item Bubbling

Bubbles with C<< Clay::UI::Enum::Bubble->IF_CONTINUE >>: the parent
sees the event when the widget has no C<OnPress> listener or all its
listeners return C<< Clay::UI::Enum::Result->CONTINUE >>, and so on
upwards. An ancestor never gets a second C<OnPress> of its own.

=item Order

After the frame's hover events, before C<OnRelease> and C<OnScroll>.
Dropped when an earlier listener removed the widget from the tree.

=back

=head1 ACCESSORS

=head2 x

	my $x = $event->x;

The horizontal pointer position when the press was seen, in layout
units: what Clay reports for the frame in C<render>, or the C<x> passed
to C<update> (default 0).

=head2 y

	my $y = $event->y;

The vertical pointer position, like L</x>.

=head2 button

	my $button = $event->button;

The mouse button, always C<1> (primary) when Clay::UI fires the event:
Clay's pointer state has no buttons. A constructor parameter, so code
that fires its own C<OnPress> can pass another number.

=head2 Inherited accessors

C<name> is C<'OnPress'> and C<bubble_mode> is C<IF_CONTINUE>.
C<target> is the pressed widget, C<current_target> the widget whose
listeners run right now, C<handled_by> and C<result> tell where the
event stopped (see L<Clay::UI::Events::Event>).

=head1 CONSTRUCTOR

	my $event = Clay::UI::Events::OnPress->new(x => 10, y => 20, button => 1);

All parameters are optional: C<x> and C<y> default to 0, C<button> to
1; C<name> and C<bubble_mode> as in L<Clay::UI::Events::Event/new>.
Clay::UI creates the event itself; construct one only to fire it
yourself with L<Clay::UI::Role::Events::Emitter/fire_event>.

=head1 CLASS METHODS

=head2 event_name

	my $name = Clay::UI::Events::OnPress->event_name;    # 'OnPress'

Returns C<'OnPress'>, the event name listeners register for with C<on>
and the default C<name> of a new event (see
L<Clay::UI::Events::Event/event_name>).

=head1 SEE ALSO

L<Clay::UI::Events::OnRelease>, L<Clay::UI::Role::Interaction::Pressable>,
L<Clay::UI::Interaction/PRESS AND RELEASE>, L<Clay::UI/EVENTS>.

=cut
