package Clay::UI::Events::OnScroll;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Events::Event;

class Clay::UI::Events::OnScroll :isa(Clay::UI::Events::Event) :strict(params) {
	field $delta_x :param :reader = 0;
	field $delta_y :param :reader = 0;

	method event_name :common { 'OnScroll' }
}

1;

__END__

=head1 NAME

Clay::UI::Events::OnScroll - fired when a scroll container's scroll position changed

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Layout::HasScroll;

	class My::Panel :strict(params) :does(Clay::UI::Box) {}
	class My::List  :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Layout::HasScroll)
	{}

	my $list = My::List->new(
		id     => 'list',
		layout => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing => { width => sizing_fixed(100), height => sizing_fixed(50) },
		},
	);
	$list->add_child(map {
		My::Panel->new(layout => {
			sizing => { width => sizing_grow(), height => sizing_fixed(20) },
		})
	} 1 .. 10);
	$list->on('OnScroll', sub ($event) {
		say 'scrolled by ', $event->delta_x, ',', $event->delta_y;
		return;
	});

	my $ui = Clay::UI->new(width => 200, height => 200, root => $list);
	$ui->render(pointer_state => { x => 10, y => 10, down => 0 });
	$ui->render(scroll_delta => { x => 0, y => -3 });   # prints "scrolled by 0,-30"

=head1 DESCRIPTION

C<OnScroll> fires during L<Clay::UI/render> at a scroll container (a
widget composing L<Clay::UI::Role::Layout::HasScroll>) whose scroll
position changed in this frame: through wheel input (C<scroll_delta>),
drag scrolling (C<enable_drag_scrolling>) or the momentum that
follows drag scrolling (wheel input has no momentum). It does not fire
for your own calls to L<Clay::UI/scroll_to> or
L<Clay::XS/set_scroll_position>, with one exception: a
C<set_scroll_position> beyond the content is clamped by the next
C<render>, and that clamp fires C<OnScroll> (the delta runs from the
position you set to the clamped one). C<scroll_to> clamps the position
itself, so it never fires C<OnScroll>. A synthetic L<Clay::UI::Interaction/update> fires
it for every entry of its C<scrolled> argument.

=over 4

=item Name

C<'OnScroll'>.

=item Received by

Each scroll container that moved, one event per container.

=item Bubbling

Bubbles with C<< Clay::UI::Enum::Bubble->IF_CONTINUE >>: the parent
sees the event when the container has no C<OnScroll> listener or all
its listeners return C<< Clay::UI::Enum::Result->CONTINUE >>.

=item Order

Last in the frame, after the hover events, C<OnPress> and
C<OnRelease>, in tree order. Dropped when an earlier listener removed
the container from the tree.

=back

=head1 ACCESSORS

=head2 delta_x

	my $dx = $event->delta_x;

How far the horizontal scroll position moved in this frame, in layout
units: new position minus old. Scroll positions are 0 at the left and
negative when scrolled right, so scrolling right gives a negative
C<delta_x>.

=head2 delta_y

	my $dy = $event->delta_y;

How far the vertical scroll position moved, like L</delta_x>;
scrolling down gives a negative C<delta_y>. Read the new position with
L<Clay::UI/scroll_state>.

=head2 Inherited accessors

C<name> is C<'OnScroll'> and C<bubble_mode> is C<IF_CONTINUE>.
C<target> is the scroll container, C<current_target> the widget whose
listeners run right now, C<handled_by> and C<result> tell where the
event stopped (see L<Clay::UI::Events::Event>).

=head1 CONSTRUCTOR

	my $event = Clay::UI::Events::OnScroll->new(delta_x => 0, delta_y => -30);

Both parameters are optional and default to 0; C<name> and
C<bubble_mode> as in L<Clay::UI::Events::Event/new>.

=head1 CLASS METHODS

=head2 event_name

	my $name = Clay::UI::Events::OnScroll->event_name;    # 'OnScroll'

Returns C<'OnScroll'>, the event name listeners register for with C<on>
and the default C<name> of a new event (see
L<Clay::UI::Events::Event/event_name>).

=head1 SEE ALSO

L<Clay::UI::Role::Layout::HasScroll>, L<Clay::UI/scroll_state>,
L<Clay::UI/scroll_to>, L<Clay::UI/EVENTS>.

=cut
