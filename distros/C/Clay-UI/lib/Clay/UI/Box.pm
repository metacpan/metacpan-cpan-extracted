package Clay::UI::Box;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasBackground;
use Clay::UI::Role::Style::HasBorder;
use Clay::UI::Role::Style::HasCornerRadius;
use Clay::UI::Role::Layout::HasFloating;
use Clay::UI::Role::Events::Emitter;

role Clay::UI::Box
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasBackground)
	:does(Clay::UI::Role::Style::HasBorder)
	:does(Clay::UI::Role::Style::HasCornerRadius)
	:does(Clay::UI::Role::Layout::HasFloating)
	:does(Clay::UI::Role::Events::Emitter)
{}

1;

__END__

=head1 NAME

Clay::UI::Box - styled container widget role for Clay::UI

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(sizing_fixed sizing_grow padding_all CLAY_TOP_TO_BOTTOM);
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Text;

	class My::Box   :strict(params) :does(Clay::UI::Box) {}
	class My::Label :strict(params) :does(Clay::UI::Text) {}

	my $sidebar = My::Box->new(
		id               => 'sidebar',
		layout           => {
			sizing           => { width => sizing_fixed(200), height => sizing_grow() },
			padding          => padding_all(8),
			child_gap        => 4,
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
		background_color => [40, 50, 60, 255],
		corner_radius    => 6,
		border_color     => [80, 80, 80, 255],
		border_width     => 1,
	);
	$sidebar->add_child(map { My::Label->new(text => $_) } qw(Home Search Settings));

	my $ui = Clay::UI->new(width => 800, height => 600, root => $sidebar);
	my $commands = $ui->render;

	$sidebar->background_color([60, 70, 80, 255]);    # shown from the next render on

=head1 DESCRIPTION

C<Clay::UI::Box> is the general-purpose container widget: an element
that holds any children and has every layout and style attribute -
sizing, padding and child placement, background colour, border, corner
radius and floating. Most widget classes start from it.

Like every widget in Clay::UI it is a role, so that you can combine it
with other roles in a class of your own. Compose it in a class (as
C<My::Box> above) to get a widget you can construct; add interaction
roles such as L<Clay::UI::Role::Interaction::Pressable> to make the
box react to the pointer.

All attributes are constructor parameters and read/write accessors, so
a box's layout and style can change at any time; the change shows at
the next C<render>. Values are checked when they are set (at
construction or by the accessor) and a bad value dies there, naming
the attribute. The box keeps its own copy of every value and every
read returns a new copy, so changing a hash or array after passing it
in, or one an accessor returned, does not change the box. Every write
bumps the revision (L<Clay::UI::Revision>); reads never do.

Declare consumer classes C<:strict(params)>, so that a misspelled
constructor parameter dies instead of being ignored:

	class My::Box :strict(params) :does(Clay::UI::Box) {}

=head1 AT A GLANCE

Everything a Box has, with the role that documents it.

=head2 Constructor parameters and attributes

=over 4

=item L<id|Clay::UI::Role::Core::Element/id>

Element id, set at construction only (read-only reader).

=item L<layout|Clay::UI::Role::Layout::HasLayout/layout>

Sizing, padding, child gap, child alignment, layout direction, line
gap and line sizing.

=item L<background_color|Clay::UI::Role::Style::HasBackground/background_color>

Fill colour.

=item L<border_color|Clay::UI::Role::Style::HasBorder/border_color>

Border colour.

=item L<border_width|Clay::UI::Role::Style::HasBorder/border_width>

Border widths: one number or per side.

=item L<corner_radius|Clay::UI::Role::Style::HasCornerRadius/corner_radius>

Corner radius: one number or per corner.

=item L<floating|Clay::UI::Role::Layout::HasFloating/floating>

Take the box out of the layout and attach it to another element.

=item L<width_group|Clay::UI::Role::Layout::HasSizingGroup/width_group>

Share the width with other elements of the same group.

=item L<height_group|Clay::UI::Role::Layout::HasSizingGroup/height_group>

Share the height with other elements of the same group.

=back

=head2 Children

=over 4

=item L<add_child|Clay::UI::Role::Core::Container/add_child>

Append children.

=item L<remove_child|Clay::UI::Role::Core::Container/remove_child>

Remove the given children.

=item L<remove_child_with_id|Clay::UI::Role::Core::Container/remove_child_with_id>

Remove children by id.

=item L<remove_children_with|Clay::UI::Role::Core::Container/remove_children_with>

Remove children matching a test.

=item L<clear_children|Clay::UI::Role::Core::Container/clear_children>

Remove all children.

=item L<children|Clay::UI::Role::Core::Element/children>

The children, as a new arrayref.

=item L<get_children_with|Clay::UI::Role::Core::Element/get_children_with>

The children matching a test.

=item L<has_child|Clay::UI::Role::Core::Element/has_child>

Whether a widget is a child.

=item L<add_internal_children|Clay::UI::Role::Core::Element/add_internal_children>, L<remove_internal_children|Clay::UI::Role::Core::Element/remove_internal_children>, L<internal_children|Clay::UI::Role::Core::Element/internal_children>, L<layout_children|Clay::UI::Role::Core::Element/layout_children>

Helpers a widget class lays out next to its user's children.

=item L<descendants|Clay::UI::Role::Core::Element/descendants>

Every widget below this one, in layout pre-order.

=back

=head2 Tree

=over 4

=item L<parent|Clay::UI::Role::Layout::HasParent/parent>

The widget this one is attached to.

=item L<root|Clay::UI::Role::Layout::HasParent/root>

The topmost widget above this one.

=item L<ui|Clay::UI::Role::Layout::HasParent/ui>

The L<Clay::UI> this widget is part of.

=item L<contains|Clay::UI::Role::Layout::HasParent/contains>

Whether a widget is this one or below it.

=item L<tree_changed|Clay::UI::Role::Layout::HasParent/tree_changed>

The hook a subclass overrides to react when the widget joins or
leaves a tree.

=back

=head2 Events

=over 4

=item L<on|Clay::UI::Role::Events::Listener/on>

Register a listener for an event name.

=item L<handlers_for|Clay::UI::Role::Events::Listener/handlers_for>

The listeners registered for an event name.

=item L<fire_event|Clay::UI::Role::Events::Emitter/fire_event>

Fire an event at this box; it bubbles up through the parents.

=back

=head2 Declaration and extension

=over 4

=item L<to_config|Clay::UI::Role::Core::Element/to_config>

The declaration (the hash of settings Clay receives for the element).

=item L<resolve_id|Clay::UI::Role::Core::Element/resolve_id>

The id the layout pass uses for the box.

=item L<mark_changed|Clay::UI::Role::Core::Element/mark_changed>

Bump the revision from a setter of your own.

=item C<contribute_layout>, C<contribute_background>, C<contribute_border>, C<contribute_corner_radius>, C<contribute_floating>, C<contribute_sizing_group>

The methods that add each part to the declaration; see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>.

=back

=head1 COMPOSED ROLES

C<Clay::UI::Box> composes:

=over 4

=item *

L<Clay::UI::Role::Core::Container> (children), which composes
L<Clay::UI::Role::Core::Element>, L<Clay::UI::Role::Layout::HasSizingGroup>,
L<Clay::UI::Role::Layout::HasParent> and L<Clay::UI::Role::Events::Listener>;

=item *

L<Clay::UI::Role::Layout::HasLayout>;

=item *

L<Clay::UI::Role::Style::HasBackground>;

=item *

L<Clay::UI::Role::Style::HasBorder>;

=item *

L<Clay::UI::Role::Style::HasCornerRadius>;

=item *

L<Clay::UI::Role::Layout::HasFloating>;

=item *

L<Clay::UI::Role::Events::Emitter>.

=back

A Box does not scroll. For a styled scroll container, compose
L<Clay::UI::Role::Layout::HasScroll> in the same class (it then needs
an C<id>):

	class My::ScrollBox :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Layout::HasScroll) {}

A Box does not react to the pointer by
itself: add L<Clay::UI::Role::Interaction::Hoverable>,
L<Clay::UI::Role::Interaction::Pressable> or
L<Clay::UI::Role::Interaction::Focusable>.

=head1 SEE ALSO

L<Clay::UI>, L<Clay::UI::Text>, L<Clay::UI::Grid>, L<Clay::Manual>,
L<Clay::Cookbook>, L<Clay::XS::Structs>.

=cut
