package Clay::UI::Role::Interaction::Hoverable;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Role::Layout::HasParent;
use Clay::UI::Role::Events::Emitter;
use Clay::UI::Role::Style::HasStates;
use Clay::UI::Events::OnHoverStart;
use Clay::UI::Events::OnHoverStopped;
use Clay::UI::_error qw(croak_ui);

role Clay::UI::Role::Interaction::Hoverable :does(Clay::UI::Role::Layout::HasParent)
                                            :does(Clay::UI::Role::Events::Emitter)
                                            :does(Clay::UI::Role::Style::HasStates) {
	ADJUST {
		croak_ui "Clay::UI: " . ref($self) . " composes Clay::UI::Role::Interaction::Hoverable on a text node;"
			. " Clay cannot report the pointer over text elements - wrap the text in an Element"
			if $self->DOES('Clay::UI::Role::Core::TextNode');
	}

	# The UI's interaction tracker owns the state; a widget outside a
	# UI is never hovered.
	method is_hovered () {
		my $ui = $self->ui;
		return defined $ui ? $ui->interaction->is_hovered($self) : 0;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Interaction::Hoverable - role for widgets that track the pointer hovering over them

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::XS qw(sizing_grow);
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Hoverable;

	class My::Tile :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Hoverable)
	{}

	my $tile = My::Tile->new(
		id     => 'tile',
		layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
	);
	$tile->on('OnHoverStart',   sub ($event) { say 'entered'; return });
	$tile->on('OnHoverStopped', sub ($event) { say 'left';    return });

	my $ui = Clay::UI->new(width => 100, height => 100, root => $tile);
	$ui->render;
	$ui->render(pointer_state => { x => 50, y => 50, down => 0 });     # entered
	say $tile->is_hovered;                                             # 1
	$ui->render(pointer_state => { x => 500, y => 500, down => 0 });   # left

=head1 DESCRIPTION

A widget that composes this role is I<hovered> while the pointer is
over it, and receives:

=over 4

=item *

L<Clay::UI::Events::OnHoverStart> in the frame the pointer comes over
it;

=item *

L<Clay::UI::Events::OnHoverStopped> in the frame the pointer leaves it,
or at once when it is removed from the tree while hovered.

=back

Neither event bubbles: every hovered widget, nested ones included, gets
its own. Widgets that do not compose Hoverable are never hovered and get
no hover events, although L<Clay::UI::Interaction/under_pointer> lists
them.

No wiring is needed: L<Clay::UI/render> finds the widgets under the
pointer and fires the events before it lays out the frame (see
L<Clay::UI/HOW A FRAME WORKS>), so listeners may change the tree. The
pointer is tested against the previous frame's layout, so a widget can
be hovered from the frame after the one that first lays it out.

Hovering needs an element: composing Hoverable (or
L<Clay::UI::Role::Interaction::Pressable>) into a text widget dies at
construction with
C<Clay::UI: E<lt>classE<gt> composes Clay::UI::Role::Interaction::Hoverable on a text node;
Clay cannot report the pointer over text elements - wrap the text in an Element>.
Make the element around the text hoverable instead.


The role composes L<Clay::UI::Role::Layout::HasParent>,
L<Clay::UI::Role::Events::Emitter> and
L<Clay::UI::Role::Style::HasStates>, which provides the derived state
C<hovered>.

=head1 METHODS

=head2 is_hovered

	my $over = $widget->is_hovered;

Returns 1 while the pointer is over the widget, as of the last
L<Clay::UI/render> (or synthetic L<Clay::UI::Interaction/update>), and
0 otherwise. Returns 0 for a widget that does not belong to a
Clay::UI. A disabled widget (L<Clay::UI::Role::Interaction::Disableable>)
is still hovered.

=head1 SEE ALSO

L<Clay::UI::Events::OnHoverStart>, L<Clay::UI::Events::OnHoverStopped>,
L<Clay::UI::Role::Interaction::Pressable>, L<Clay::UI::Interaction>.

=cut
