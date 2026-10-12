package Clay::UI::Role::Core::Stateful;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Clay::UI::_error qw(croak_ui);

role Clay::UI::Role::Core::Stateful :does(Clay::UI::Role::Core::Element) {
	ADJUST {
		croak_ui "Clay::UI::Role::Core::Stateful: widget '" . (ref $self) . "' requires an explicit 'id'"
			unless defined $self->id;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Core::Stateful - require an explicit id on a Clay::UI widget

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI::Role::Core::Stateful;

	class My::Tracked :strict(params) :does(Clay::UI::Role::Core::Stateful) {}

	my $panel = My::Tracked->new(id => 'main-panel');    # ok
	eval { My::Tracked->new } or warn $@;               # dies: no id

=head1 DESCRIPTION

C<Clay::UI::Role::Core::Stateful> extends
L<Clay::UI::Role::Core::Element> and makes the C<id> constructor
parameter mandatory. Compose it for widgets whose Clay element needs
the same id in every frame because Clay keeps state for it between
frames. L<Clay::UI::Role::Layout::HasScroll> composes it: Clay stores a
scroll container's scroll position under its element id. Without an
C<id> a widget gets an id derived from its position (see
L<Clay::UI::Role::Core::Element/resolve_id>), which changes when the
widget moves.

Hover, press and focus do not need an id: L<Clay::UI::Interaction>
tracks widgets by reference.

The role adds no methods. The constructor dies with
C<Clay::UI::Role::Core::Stateful: widget 'My::Tracked' requires an explicit 'id'>
when C<id> is missing or undef.


=head1 SEE ALSO

L<Clay::UI::Role::Core::Element/id>,
L<Clay::UI::Role::Layout::HasScroll>.

=cut
