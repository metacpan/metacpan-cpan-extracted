package Clay::UI::Role::Interaction::Focusable;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Role::Layout::HasParent;
use Clay::UI::Role::Events::Emitter;
use Clay::UI::Role::Style::HasStates;
use Clay::UI::Revision qw(bump_revision);
use Clay::UI::_error qw(croak_ui);

role Clay::UI::Role::Interaction::Focusable :does(Clay::UI::Role::Layout::HasParent)
                                            :does(Clay::UI::Role::Events::Emitter)
                                            :does(Clay::UI::Role::Style::HasStates) {
	# Whether the widget may take focus as far as its users are concerned;
	# can_focus also asks the widget's class and whether it is disabled.
	field $wants_focus :param(can_focus) = 1;

	ADJUST {
		$wants_focus = _focus_flag($wants_focus);
	}

	# The reader answers whether the widget can take focus now; the writer
	# records the wish. Not drawn, so a write does not bump the revision,
	# but a widget that can no longer take focus loses it at once.
	method can_focus (@new) {
		if (@new) {
			croak_ui "Clay::UI: 'can_focus' takes one value" unless @new == 1;
			$wants_focus = _focus_flag($new[0]);
			my $ui = $self->ui;
			$ui->interaction->release_ineligible($self) if defined $ui;
		}
		return 0 unless $wants_focus && $self->accepts_focus;
		return 0 if $self->DOES('Clay::UI::Role::Interaction::Disableable') && $self->disabled;
		return 1;
	}

	# Whether widgets of the class take focus at all; a subclass that never
	# does (a radio button whose group takes it) overrides this.
	method accepts_focus () {
		return 1;
	}

	# For a class whose accepts_focus answer depends on its own state: call
	# after that state changed. A widget that can no longer take focus loses
	# it at once.
	method focus_eligibility_changed () {
		my $ui = $self->ui;
		$ui->interaction->release_ineligible($self) if defined $ui;
		bump_revision();
		return $self;
	}

	sub _focus_flag ($value) {
		croak_ui "Clay::UI: 'can_focus' must be a plain boolean value" if ref $value;
		return $value ? 1 : 0;
	}

	method is_focused () {
		my $ui = $self->ui;
		return defined $ui ? $ui->interaction->is_focused($self) : 0;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Interaction::Focusable - role for widgets that can take the keyboard focus

=head1 SYNOPSIS

	use v5.22;
	use warnings;
	use feature 'signatures';
	no warnings 'experimental::signatures';

	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Role::Interaction::Focusable;
	use Clay::UI::Role::Interaction::Disableable;

	class My::Panel     :strict(params) :does(Clay::UI::Box) {}
	class My::TextInput :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Focusable)
		:does(Clay::UI::Role::Interaction::Disableable)
	{}

	my $input = My::TextInput->new(id => 'name');
	$input->on('OnFocus', sub ($event) { say 'got the focus';  return });
	$input->on('OnBlur',  sub ($event) { say 'lost the focus'; return });

	my $root = My::Panel->new(id => 'form');
	$root->add_child($input);
	my $ui = Clay::UI->new(width => 400, height => 300, root => $root);

	$ui->interaction->set_focused_widget($input);   # got the focus
	say $input->is_focused;                         # 1
	$input->disabled(1);    # lost the focus; can_focus is 0 until enabled

=head1 DESCRIPTION

A widget that composes this role can take the focus: the one widget of
a L<Clay::UI> that receives keyboard input. The UI's interaction
tracker (L<Clay::UI::Interaction>) holds which widget has the focus and
moves it (L<Clay::UI::Interaction/FOCUS>); this role says whether the
widget may take it (L</can_focus>) and whether it has it
(L</is_focused>).

The widget receives L<Clay::UI::Events::OnFocus> when it gets the focus
and L<Clay::UI::Events::OnBlur> when it loses it. Both bubble with
C<IF_CONTINUE>.

The role composes L<Clay::UI::Role::Layout::HasParent>,
L<Clay::UI::Role::Events::Emitter> and
L<Clay::UI::Role::Style::HasStates>, which provides the derived state
C<focused>.

=head1 PARAMETERS

=head2 can_focus (constructor parameter)

	My::TextInput->new(can_focus => 0);

Constructor parameter: whether the widget's users want it to take the
focus, any plain boolean value; default 1. Dies for a reference with
C<Clay::UI: 'can_focus' must be a plain boolean value>.

=head1 METHODS

=head2 can_focus

	my $eligible = $widget->can_focus;    # 1 or 0
	$widget->can_focus(0);

Reads whether the widget can take the focus now. It can when all of
these hold:

=over 4

=item *

its users want it to: the C<can_focus> constructor parameter, or the
last value written;

=item *

its class accepts the focus (L</accepts_focus>);

=item *

it is not disabled, when it composes
L<Clay::UI::Role::Interaction::Disableable>.

=back

A write records what the users want, whatever the widget's state: a
widget given C<can_focus(1)> while disabled can take the focus once it
is enabled, and one built with C<< can_focus => 0 >> stays unable to
take it when it is enabled. A write takes one plain boolean value,
returns what reading returns now, and does not bump the revision
(nothing drawn depends on it). When the widget has the focus and can no
longer take it, it loses the focus at once to its heir and gets
C<OnBlur> (see L<Clay::UI::Interaction/release_ineligible>). Dies with
C<Clay::UI: 'can_focus' must be a plain boolean value> or
C<Clay::UI: 'can_focus' takes one value>.


A widget whose C<can_focus> is 0 is skipped by C<focus_next> and
C<focus_previous>, rejected by C<set_focused_widget> (which dies), and
means "the focus stays" when a
L<Clay::UI::Role::Interaction::HasFocusOrder> returns it.

=head2 accepts_focus

	method accepts_focus :override () { return 0 }

Whether widgets of the class take the focus at all; returns 1 here. A
subclass overrides it to return 0 when its widgets never take the
focus themselves, for example a radio button whose group takes the
focus for all its buttons. L</can_focus> then returns 0 whatever was
written. A class cannot override a method of a role it composes itself,
so the override goes into a subclass of the class that composes
Focusable:

	class My::RadioButton :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Focusable) {}
	class My::GroupedRadioButton :strict(params) :isa(My::RadioButton) {
		method accepts_focus :override () { return 0 }
	}

When the answer depends on the widget's own state (a rating that
takes no focus while it is read-only), the setter of that state calls
L</focus_eligibility_changed>.

=head2 focus_eligibility_changed

	$self->focus_eligibility_changed;

For a class whose L</accepts_focus> answer depends on its own state:
call it from the setter of that state, after the state changed. A
focused widget that can no longer take the focus loses it at once to
its heir and gets C<OnBlur> before this returns (see
L<Clay::UI::Interaction/release_ineligible>); a widget outside a
L<Clay::UI> is left alone. Bumps the revision
(L<Clay::UI::Revision>), since such state usually changes how the
widget looks. Returns the widget.

	class My::Rating :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Interaction::Focusable) {}
	class My::ReadOnlyRating :strict(params) :isa(My::Rating) {
		field $read_only = 0;

		method accepts_focus :override () { return !$read_only }

		method read_only ($value) {
			$read_only = $value ? 1 : 0;
			$self->focus_eligibility_changed;
			return $self;
		}
	}

=head2 is_focused

	my $has_focus = $widget->is_focused;

Returns 1 while this widget has the focus of its L<Clay::UI>, 0
otherwise. Returns 0 for a widget that does not belong to a Clay::UI.

=head1 SEE ALSO

L<Clay::UI::Interaction/FOCUS>, L<Clay::UI::Events::OnFocus>,
L<Clay::UI::Events::OnBlur>, L<Clay::UI::Role::Interaction::HasFocusOrder>,
L<Clay::UI::Role::Interaction::Disableable>.

=cut
