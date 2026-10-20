package Clay::UI::Events::OnHoverStart;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Enum::Bubble;
use Clay::UI::Events::Event;

class Clay::UI::Events::OnHoverStart :isa(Clay::UI::Events::Event) :strict(params) {
	method event_name :common { 'OnHoverStart' }
	method default_bubble_mode :common { Clay::UI::Enum::Bubble->NEVER }
}

1;

__END__

=head1 NAME

Clay::UI::Events::OnHoverStart - fired when the pointer comes over a hoverable widget

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
	$tile->on('OnHoverStart', sub ($event) {
		say 'pointer entered ', $event->target->id;
		return;
	});

	my $ui = Clay::UI->new(width => 100, height => 100, root => $tile);
	$ui->render;                                                     # first layout
	$ui->render(pointer_state => { x => 50, y => 50, down => 0 });   # "pointer entered tile"

=head1 DESCRIPTION

C<OnHoverStart> fires at a L<Clay::UI::Role::Interaction::Hoverable>
widget in the frame it comes under the pointer: during
L<Clay::UI/render>, or during a synthetic
L<Clay::UI::Interaction/update>. The widget is hovered (C<is_hovered>
is 1) when its listeners run. Its partner is
L<Clay::UI::Events::OnHoverStopped>.

=over 4

=item Name

C<'OnHoverStart'>.

=item Received by

The Hoverable widget that came under the pointer. Every such widget
gets its own event, nested ones included; a widget that is not
Hoverable gets none.

=item Bubbling

Does not bubble by default (C<< Clay::UI::Enum::Bubble->NEVER >>), like
the DOM's C<mouseenter>.

=item Order

All C<OnHoverStart> events of a frame fire after its
C<OnHoverStopped> events and before C<OnPress>, in tree order. An event
whose widget is no longer hovered when its turn comes (an earlier
listener removed it, say) is dropped.

=back

=head1 ACCESSORS

No payload. The inherited accessors (see L<Clay::UI::Events::Event>):

=over 4

=item name

C<'OnHoverStart'>.

=item bubble_mode

C<< Clay::UI::Enum::Bubble->NEVER >>.

=item target

=item current_target

The hovered widget.

=item handled_by

=item result

The hovered widget and C<HANDLED> when one of its listeners returned
anything but C<< Clay::UI::Enum::Result->CONTINUE >>.

=back

=head1 CLASS METHODS

=head2 event_name

	my $name = Clay::UI::Events::OnHoverStart->event_name;    # 'OnHoverStart'

Returns C<'OnHoverStart'>, the event name listeners register for with C<on>
and the default C<name> of a new event (see
L<Clay::UI::Events::Event/event_name>).

=head2 default_bubble_mode

	my $mode = Clay::UI::Events::OnHoverStart->default_bubble_mode;    # Bubble->NEVER

Returns C<< Clay::UI::Enum::Bubble->NEVER >>, the default
C<bubble_mode> of a new event: C<OnHoverStart> does not bubble (see
L<Clay::UI::Events::Event/default_bubble_mode>).

=head1 SEE ALSO

L<Clay::UI::Events::OnHoverStopped>,
L<Clay::UI::Role::Interaction::Hoverable>, L<Clay::UI/EVENTS>.

=cut
