package Clay::UI::Role::Style::HasStates;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Revision qw(bump_revision);
use Clay::UI::_error qw(croak_ui);

# Derived states and the reader each one is answered by. A widget
# without the reader (no matching interaction role) never has the state.
my %DERIVED = (hovered => 'is_hovered', pressed => 'is_pressed', focused => 'is_focused', disabled => 'disabled');

role Clay::UI::Role::Style::HasStates {
	field %_states;

	sub _require_user_state ($name) {
		croak_ui "Clay::UI: a state name must be a non-empty string"
			unless defined $name && !ref $name && length $name;
		croak_ui "Clay::UI: state '$name' is derived and cannot be set" if exists $DERIVED{$name};
		return;
	}

	method add_state ($name) {
		_require_user_state($name);
		$_states{$name} = 1;
		bump_revision();
		return $self;
	}

	method remove_state ($name) {
		_require_user_state($name);
		delete $_states{$name};
		bump_revision();
		return $self;
	}

	method has_state ($name) {
		my $reader = $DERIVED{$name};
		return exists $_states{$name} unless defined $reader;
		return $self->can($reader) && $self->$reader ? 1 : 0;
	}

	method toggle_state ($name) {
		_require_user_state($name);
		if (exists $_states{$name}) {
			delete $_states{$name};
		} else {
			$_states{$name} = 1;
		}
		bump_revision();
		return $self;
	}

	# Clears the user states; derived states follow interaction.
	method clear_states {
		%_states = ();
		bump_revision();
		return $self;
	}

	# The user states, then the active derived states; in scalar context
	# how many there are.
	method states {
		my @active = (keys(%_states), grep { $self->has_state($_) } sort keys %DERIVED);
		return @active;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Style::HasStates - named states such as selected or loading on a Clay::UI widget

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI::Role::Core::Container;
	use Clay::UI::Role::Style::HasStates;

	class My::Item :strict(params)
		:does(Clay::UI::Role::Core::Container)
		:does(Clay::UI::Role::Style::HasStates)
	{}

	my $item = My::Item->new(id => 'item-1');
	$item->add_state('loading');
	$item->has_state('loading');       # 1
	$item->remove_state('loading');
	$item->toggle_state('selected');   # on
	my @active = $item->states;        # ('selected')
	$item->clear_states;

=head1 DESCRIPTION

C<Clay::UI::Role::Style::HasStates> gives a widget a set of state
names, so that a theme or renderer has one place to ask what the widget
is doing right now. There are two kinds of states:

=over 4

=item user states

Any name you choose, such as C<selected>, C<loading> or C<error>. You
add and remove them; the set holds each name once and has no order.
A name is a plain, non-empty string; anything else dies.

=item derived states

C<hovered>, C<pressed>, C<focused> and C<disabled>. They are never
stored: C<has_state> and C<states> ask the widget each time (see
L</DERIVED STATES>), and they cannot be added, removed or toggled.

=back

The interaction roles L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Role::Interaction::Pressable>,
L<Clay::UI::Role::Interaction::Focusable> and
L<Clay::UI::Role::Interaction::Disableable> compose this role already;
compose it yourself only for a widget that needs user states without
any of them.

States do not change the declaration: Clay never sees them. A
contribute method of your own (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>) can turn
them into colours, for example. Such a method must not set a value
that another method of the class also sets: a widget that picks its
C<background_color> by state must leave the C<background_color>
attribute unset, or not compose L<Clay::UI::Role::Style::HasBackground>
at all. Every change bumps the revision
(L<Clay::UI::Revision>).

=head1 METHODS

=head2 add_state

	$widget->add_state('selected');

Adds a user state. Adding a state that is already set changes nothing,
but still bumps the revision. Returns the widget. Dies with
C<Clay::UI: a state name must be a non-empty string> for undef, a
reference or the empty string, and with
C<Clay::UI: state 'hovered' is derived and cannot be set> for a derived
state.

=head2 remove_state

	$widget->remove_state('selected');

Removes a user state; removing one that is not set changes nothing.
Bumps the revision and returns the widget. Dies for a derived state,
like L</add_state>.

=head2 toggle_state

	$widget->toggle_state('selected');

Adds the user state if it is not set, removes it if it is. Bumps the
revision and returns the widget. Dies for a derived state.

=head2 has_state

	if ($widget->has_state('selected')) { ... }
	if ($widget->has_state('hovered'))  { ... }

Returns true if the state is active: a user state that is set, or a
derived state that currently applies. A name that is neither is
false.

=head2 clear_states

	$widget->clear_states;

Removes every user state. Derived states are not affected; they keep
following the widget. Bumps the revision and returns the widget.

=head2 states

	my @active = $widget->states;

Returns the names of all active states, user and derived, as a list in
no particular order; in scalar context, how many there are.

=head1 DERIVED STATES

Each derived state is answered by a reader of the widget. A widget
without that reader (it does not compose the matching role) never has
the state.

=over 4

=item C<hovered>

C<is_hovered> of L<Clay::UI::Role::Interaction::Hoverable>: the pointer
is over the widget.

=item C<pressed>

C<is_pressed> of L<Clay::UI::Role::Interaction::Pressable>.

=item C<focused>

C<is_focused> of L<Clay::UI::Role::Interaction::Focusable>.

=item C<disabled>

C<disabled> of L<Clay::UI::Role::Interaction::Disableable>.

=back

C<is_hovered>, C<is_pressed> and C<is_focused> ask the UI's
L<Clay::UI::Interaction>, which updates them during C<render>.

=head1 SEE ALSO

L<Clay::UI::Interaction>, L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Role::Interaction::Disableable>.

=cut
