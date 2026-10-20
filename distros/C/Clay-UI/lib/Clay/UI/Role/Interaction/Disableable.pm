package Clay::UI::Role::Interaction::Disableable;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Revision qw(bump_revision);
use Clay::UI::Role::Layout::HasParent;
use Clay::UI::Role::Style::HasStates;
use Clay::UI::_error qw(croak_ui);

role Clay::UI::Role::Interaction::Disableable :does(Clay::UI::Role::Layout::HasParent)
                                              :does(Clay::UI::Role::Style::HasStates) {
	field $disabled :param = 0;

	ADJUST {
		$disabled = _disabled_flag($disabled);
	}

	sub _disabled_flag ($value) {
		croak_ui "Clay::UI: 'disabled' must be a plain boolean value" if ref $value;
		return $value ? 1 : 0;
	}

	# A widget that becomes disabled loses its focus, arming and press at
	# once, through the tracker.
	method disabled (@new) {
		return $disabled unless @new;
		croak_ui "Clay::UI: 'disabled' takes one value" unless @new == 1;
		my $value = _disabled_flag($new[0]);
		return $disabled if $value == $disabled;
		$disabled = $value;
		bump_revision();
		my $ui = $self->ui;
		$ui->interaction->release_ineligible($self) if defined $ui;
		return $disabled;
	}

	method is_enabled () {
		return $disabled ? 0 : 1;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Interaction::Disableable - role for widgets that can be switched off

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Focusable;
	use Clay::UI::Role::Interaction::Pressable;
	use Clay::UI::Role::Interaction::Disableable;

	class My::Button :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Focusable)
		:does(Clay::UI::Role::Interaction::Pressable)
		:does(Clay::UI::Role::Interaction::Disableable)
	{}

	my $button = My::Button->new(id => 'save', disabled => 1);
	my $ui     = Clay::UI->new(width => 400, height => 300, root => $button);

	say $button->can_focus;     # 0 while disabled
	$button->disabled(0);       # enabled again: can take the focus and be pressed
	say $button->is_enabled;    # 1
	say $button->can_focus;     # 1

=head1 DESCRIPTION

A widget that composes this role can be disabled. While it is
disabled:

=over 4

=item *

it cannot take the focus: L<Clay::UI::Role::Interaction::Focusable/can_focus>
returns 0, so C<focus_next> and C<focus_previous> skip it and
C<set_focused_widget> rejects it. The widget's own C<can_focus> wish is
kept for when it is enabled again;

=item *

it is never armed or pressed (see
L<Clay::UI::Interaction/PRESS AND RELEASE>): a press over it fires no
C<OnPress> at it, a release no C<OnRelease>, and C<is_pressed> stays 0.
It is still hovered and still gets the hover events. A press over a
disabled Pressable is absorbed: a pressable card around a disabled
button gets no C<OnPress> either (see
L<Clay::UI::Interaction/PRESS AND RELEASE>);

=item *

it has the derived state C<disabled> (see
L<Clay::UI::Role::Style::HasStates>), so a style can depend on it.

=back

Disabling a widget that has the focus, or that is armed or pressed,
takes that away at once: it is disarmed and unpressed, and a focused
widget gets C<OnBlur> before the C<disabled> writer returns, while its
heir takes the focus (see L<Clay::UI::Interaction/release_ineligible>).

Disabling a widget does not disable its children; each widget has its
own C<disabled> value.

The role composes L<Clay::UI::Role::Layout::HasParent> and
L<Clay::UI::Role::Style::HasStates>.

=head1 PARAMETERS

=head2 disabled (constructor parameter)

	My::Button->new(disabled => 1);

Constructor parameter: whether the widget starts disabled, any plain
boolean value, stored as 1 or 0; default 0. Dies for a reference with
C<Clay::UI: 'disabled' must be a plain boolean value>.

=head1 METHODS

=head2 disabled

	my $off = $widget->disabled;    # 1 or 0
	$widget->disabled(1);

Reads or writes whether the widget is disabled. A write takes one plain
boolean value and returns the new value, 1 or 0. A write that changes
the value bumps the revision (L<Clay::UI::Revision>) and, when the
widget belongs to a L<Clay::UI>, releases its focus, arming and press
as described above; writing the current value does nothing. Dies with
C<Clay::UI: 'disabled' must be a plain boolean value> for a reference
and C<Clay::UI: 'disabled' takes one value> for more than one value.

=head2 is_enabled

	my $on = $widget->is_enabled;

Returns 1 while the widget is not disabled, 0 while it is.

=head1 SEE ALSO

L<Clay::UI::Role::Interaction::Focusable>,
L<Clay::UI::Role::Interaction::Pressable>, L<Clay::UI::Interaction>.

=cut
