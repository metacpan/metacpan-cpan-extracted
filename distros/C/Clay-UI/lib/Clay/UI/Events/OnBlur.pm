package Clay::UI::Events::OnBlur;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Events::Event;

class Clay::UI::Events::OnBlur :isa(Clay::UI::Events::Event) :strict(params) {
	method event_name :common { 'OnBlur' }
}

1;

__END__

=head1 NAME

Clay::UI::Events::OnBlur - fired at a widget that loses the focus

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

	my $name  = My::Input->new(id => 'name');
	my $email = My::Input->new(id => 'email');
	my $root  = My::Panel->new(id => 'form');
	$root->add_child($name, $email);
	$name->on('OnBlur', sub ($event) {
		say 'focus left ', $event->target->id;
		return;
	});

	my $ui = Clay::UI->new(width => 400, height => 300, root => $root);
	$ui->interaction->set_focused_widget($name);
	$ui->interaction->set_focused_widget($email);   # prints "focus left name"

=head1 DESCRIPTION

C<OnBlur> fires at the widget that had the focus, right after it lost
it:

=over 4

=item *

the focus moved to another widget or was cleared
(L<Clay::UI::Interaction/set_focused_widget>, C<focus_next>,
C<focus_previous>); the old widget's C<OnBlur> fires before the new
widget's L<Clay::UI::Events::OnFocus>;

=item *

the focused widget, or an ancestor, was removed from the tree (at once,
during the removal; the widget is still attached while the listeners
run, so the event bubbles through its old ancestors);

=item *

the focused widget was disabled
(L<Clay::UI::Role::Interaction::Disableable>) or its C<can_focus> was
set to false (L<Clay::UI::Role::Interaction::Focusable>).

=back

The widget no longer has the focus (C<is_focused> is 0) when its
listeners run. A widget gets C<OnBlur> only after it got C<OnFocus>.
C<render> never fires C<OnBlur> by itself.

=over 4

=item Name

C<'OnBlur'>.

=item Received by

The widget that lost the focus.

=item Bubbling

Bubbles with C<< Clay::UI::Enum::Bubble->IF_CONTINUE >>: the parent
sees the event when the widget has no C<OnBlur> listener or all its
listeners return C<< Clay::UI::Enum::Result->CONTINUE >>.

=back

=head1 ACCESSORS

No payload. The inherited accessors (see L<Clay::UI::Events::Event>):
C<name> is C<'OnBlur'>, C<bubble_mode> is C<IF_CONTINUE>, C<target> is
the widget that lost the focus, C<current_target> the widget whose
listeners run right now, and C<handled_by> and C<result> tell where the
event stopped.

=head1 CLASS METHODS

=head2 event_name

	my $name = Clay::UI::Events::OnBlur->event_name;    # 'OnBlur'

Returns C<'OnBlur'>, the event name listeners register for with C<on>
and the default C<name> of a new event (see
L<Clay::UI::Events::Event/event_name>).

=head1 SEE ALSO

L<Clay::UI::Events::OnFocus>, L<Clay::UI::Role::Interaction::Focusable>,
L<Clay::UI::Interaction/FOCUS>, L<Clay::UI::Interaction/REMOVED WIDGETS>.

=cut
