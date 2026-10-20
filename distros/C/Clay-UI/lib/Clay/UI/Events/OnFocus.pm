package Clay::UI::Events::OnFocus;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Events::Event;

class Clay::UI::Events::OnFocus :isa(Clay::UI::Events::Event) :strict(params) {
	method event_name :common { 'OnFocus' }
}

1;

__END__

=head1 NAME

Clay::UI::Events::OnFocus - fired at a widget that receives the focus

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Focusable;

	class My::Panel :strict(params) :does(Clay::UI::Box) {}
	class My::Input :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Focusable)
	{}

	my $name = My::Input->new(id => 'name');
	my $root = My::Panel->new(id => 'form');
	$root->add_child($name);
	$name->on('OnFocus', sub ($event) {
		say 'focus gained by ', $event->target->id;
		return;
	});

	my $ui = Clay::UI->new(width => 400, height => 300, root => $root);
	$ui->interaction->focus_next;   # prints "focus gained by name"

=head1 DESCRIPTION

C<OnFocus> fires at a L<Clay::UI::Role::Interaction::Focusable> widget
right after it received the focus through
L<Clay::UI::Interaction/set_focused_widget>,
L<Clay::UI::Interaction/focus_next> or
L<Clay::UI::Interaction/focus_previous>. C<render> never moves the
focus, so it never fires C<OnFocus>. The widget has the focus
(C<is_focused> is 1) when its listeners run. Its partner is
L<Clay::UI::Events::OnBlur>.

When the focus moves from one widget to another, the old widget's
C<OnBlur> fires first, then the new widget's C<OnFocus>. If an
C<OnBlur> listener moves the focus elsewhere, this C<OnFocus> is
dropped, because its widget no longer has the focus.

=over 4

=item Name

C<'OnFocus'>.

=item Received by

The widget that received the focus.

=item Bubbling

Bubbles with C<< Clay::UI::Enum::Bubble->IF_CONTINUE >>: the parent
sees the event when the widget has no C<OnFocus> listener or all its
listeners return C<< Clay::UI::Enum::Result->CONTINUE >>. A container
can therefore learn that the focus entered its subtree.

=back

=head1 ACCESSORS

No payload. The inherited accessors (see L<Clay::UI::Events::Event>):
C<name> is C<'OnFocus'>, C<bubble_mode> is C<IF_CONTINUE>, C<target>
is the focused widget, C<current_target> the widget whose listeners run
right now, and C<handled_by> and C<result> tell where the event
stopped.

=head1 CLASS METHODS

=head2 event_name

	my $name = Clay::UI::Events::OnFocus->event_name;    # 'OnFocus'

Returns C<'OnFocus'>, the event name listeners register for with C<on>
and the default C<name> of a new event (see
L<Clay::UI::Events::Event/event_name>).

=head1 SEE ALSO

L<Clay::UI::Events::OnBlur>, L<Clay::UI::Role::Interaction::Focusable>,
L<Clay::UI::Interaction/FOCUS>.

=cut
