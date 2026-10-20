package Clay::UI::Events::OnHoverStopped;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Enum::Bubble;
use Clay::UI::Events::Event;

class Clay::UI::Events::OnHoverStopped :isa(Clay::UI::Events::Event) :strict(params) {
	method event_name :common { 'OnHoverStopped' }
	method default_bubble_mode :common { Clay::UI::Enum::Bubble->NEVER }
}

1;

__END__

=head1 NAME

Clay::UI::Events::OnHoverStopped - fired when the pointer leaves a hovered widget

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::XS qw(sizing_fixed);
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Hoverable;

	class My::Panel :strict(params) :does(Clay::UI::Box) {}
	class My::Tile  :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Hoverable)
	{}

	my $tile = My::Tile->new(
		id     => 'tile',
		layout => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) } },
	);
	$tile->on('OnHoverStopped', sub ($event) {
		say 'pointer left ', $event->target->id;
		return;
	});
	my $root = My::Panel->new(id => 'root');
	$root->add_child($tile);

	my $ui = Clay::UI->new(width => 100, height => 100, root => $root);
	$ui->render;
	$ui->render(pointer_state => { x => 10, y => 10, down => 0 });   # over the tile
	$ui->render(pointer_state => { x => 90, y => 90, down => 0 });   # "pointer left tile"

=head1 DESCRIPTION

C<OnHoverStopped> fires at a hovered widget when it stops being
hovered:

=over 4

=item *

in the frame the pointer is no longer over it (during
L<Clay::UI/render> or a synthetic L<Clay::UI::Interaction/update>);

=item *

at once, during the removal, when the widget (or an ancestor) is
removed from the tree while hovered. The widget is still attached to
its parent while the listeners run.

=back

The widget is no longer hovered (C<is_hovered> is 0) when its listeners
run. A widget gets C<OnHoverStopped> only after it got
L<Clay::UI::Events::OnHoverStart>.

=over 4

=item Name

C<'OnHoverStopped'>.

=item Received by

The L<Clay::UI::Role::Interaction::Hoverable> widget that stopped being
hovered. Every such widget gets its own event, nested ones included.

=item Bubbling

Does not bubble by default (C<< Clay::UI::Enum::Bubble->NEVER >>), like
the DOM's C<mouseleave>.

=item Order

All C<OnHoverStopped> events of a frame fire first, before every other
event of the frame, in tree order. An event whose widget is hovered
again when its turn comes is dropped.

=back

=head1 ACCESSORS

No payload. The inherited accessors (see L<Clay::UI::Events::Event>):

=over 4

=item name

C<'OnHoverStopped'>.

=item bubble_mode

C<< Clay::UI::Enum::Bubble->NEVER >>.

=item target

=item current_target

The widget that stopped being hovered.

=item handled_by

=item result

That widget and C<HANDLED> when one of its listeners returned anything
but C<< Clay::UI::Enum::Result->CONTINUE >>.

=back

=head1 CLASS METHODS

=head2 event_name

	my $name = Clay::UI::Events::OnHoverStopped->event_name;    # 'OnHoverStopped'

Returns C<'OnHoverStopped'>, the event name listeners register for with C<on>
and the default C<name> of a new event (see
L<Clay::UI::Events::Event/event_name>).

=head2 default_bubble_mode

	my $mode = Clay::UI::Events::OnHoverStopped->default_bubble_mode;    # Bubble->NEVER

Returns C<< Clay::UI::Enum::Bubble->NEVER >>, the default
C<bubble_mode> of a new event: C<OnHoverStopped> does not bubble (see
L<Clay::UI::Events::Event/default_bubble_mode>).

=head1 SEE ALSO

L<Clay::UI::Events::OnHoverStart>,
L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Interaction/REMOVED WIDGETS>, L<Clay::UI/EVENTS>.

=cut
